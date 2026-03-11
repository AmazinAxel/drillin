extends AnimatedSprite2D
@onready var area = $Area2D
@onready var player = get_parent().get_node("Player")
@onready var miningParticles = $miningParticles

## Sound - Intro (drill first starts)
@export_group("Sound - Intro")
@export var intro_start_pitch := 0.6
@export var intro_target_pitch := 1.0
@export var intro_pitch_duration := 1.0
@export var intro_start_volume_db := -50.0
@export var intro_target_volume_db := 0.0
@export var intro_volume_duration := 1

## Sound - Descent (after continue clicked)
@export_group("Sound - Descent")
@export var descent_peak_pitch := 1.4
@export var descent_pitch_ramp_up_duration := 1.0
@export var descent_return_pitch := 0.6
@export var descent_pitch_ramp_down_duration := 1.0

## Sound - Fade Out (end of descent)
@export_group("Sound - Fade Out")
@export var fadeout_target_volume_db := -50.0
@export var fadeout_duration := 1
@export_range(0.0, 5.0) var sound_end_early_offset := 0.1  ## How many seconds before descent ends to start fade out + pitch return

var is_shaking = false
var darkness_overlay = null
var camera_base_offset = Vector2.ZERO
var drill_move_tween: Tween
var player_move_tween: Tween
var speed_tween: Tween
var trigger_distance := 50.0
var started = false
var show_gui_blocked = false

var energyFilled = true

func _ready() -> void:
	stop()

func _process(_delta: float) -> void:
	if not player:
		return
	var dist = global_position.distance_to(player.global_position)
	
	if dist < trigger_distance and not started and not show_gui_blocked and energyFilled:
		$f.visible = true
		$energyStaticIcon.visible = false
		if Input.is_action_just_pressed("interact"):
			started = true
			$f.visible = false
			start_drill_sequence()
	elif energyFilled:
		$f.visible = false
		
		if Globals.inDrill == false:
			# dont show the static icon when in drill!!!
			$energyStaticIcon.play("filled");
			$energyStaticIcon.visible = true
	
	$f.scale.x = abs($f.scale.x) * sign(scale.x)

func start_drill_sequence():
	play("default")
	kill_all_enemies()
	
	Globals.inDrill = true

	var camera = get_tree().get_first_node_in_group("player").get_node("Camera2D")
	var player_node = get_tree().get_first_node_in_group("player")
	
	player_node.set_physics_process(false)
	player_node.visible = false
	
	darkness_overlay = ColorRect.new()
	darkness_overlay.color = Color(0, 0, 0, 0)
	darkness_overlay.z_index = 10
	darkness_overlay.size = Vector2(9999, 9999)
	darkness_overlay.position = Vector2(-4999, -4999)
	get_tree().current_scene.add_child(darkness_overlay)
	
	z_index = 20
	
	var pan_tween = create_tween()
	pan_tween.tween_method(set_base_offset, Vector2.ZERO, Vector2(95, 0), 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	var zoom_tween = create_tween()
	zoom_tween.tween_property(camera, "zoom", Vector2(2, 2), 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	# Start drill sound low-pitched and quiet, ramp up to normal
	$drillSound.pitch_scale = intro_start_pitch
	$drillSound.volume_db = intro_start_volume_db
	
	var intro_pitch_tween = create_tween()
	intro_pitch_tween.tween_property($drillSound, "pitch_scale", intro_target_pitch, intro_pitch_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	var intro_vol_tween = create_tween()
	intro_vol_tween.tween_property($drillSound, "volume_db", intro_target_volume_db, intro_volume_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	is_shaking = true
	shake_camera_forever(camera)
	play_drill_sound_loop()
	
	miningParticles.emitting = true
	
	var dark_tween = create_tween()
	dark_tween.tween_property(darkness_overlay, "color:a", 0.6, 2.0)
	
	drill_move_tween = create_tween()
	drill_move_tween.tween_property(self, "global_position:y", global_position.y + 300.0, 25.0).set_ease(Tween.EASE_IN_OUT)
	
	player_move_tween = create_tween()
	player_move_tween.tween_property(player_node, "global_position:y", player_node.global_position.y + 300.0, 25.0).set_ease(Tween.EASE_IN_OUT)
	
	speed_tween = create_tween()
	speed_tween.tween_property(self, "speed_scale", 0.2, 25.0)
	
	await get_tree().create_timer(1.0).timeout
	var shop_layer = CanvasLayer.new()
	shop_layer.layer = 100
	shop_layer.name = "ShopLayer"
	var shop = preload("res://scenes/UI/DrillaShop.tscn").instantiate()
	shop.modulate = Color(1, 1, 1, 0)
	shop_layer.add_child(shop)
	get_tree().current_scene.add_child(shop_layer)
	
	var shop_tween = create_tween()
	shop_tween.tween_property(shop, "modulate:a", 1.0, 1.0).set_ease(Tween.EASE_IN_OUT)

func set_base_offset(value: Vector2):
	camera_base_offset = value

func shake_camera_forever(camera: Camera2D):
	var shake_strength = 1.5
	while is_shaking:
		camera.offset = camera_base_offset + Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		await get_tree().process_frame
	camera.offset = camera_base_offset

func play_drill_sound_loop():
	while is_shaking:
		$drillSound.play()
		await $drillSound.finished

func ease_in_out_custom(t: float) -> float:
	if t < 0.4:
		var normalized = t / 0.4
		return normalized * normalized
	else:
		var normalized = (t - 0.4) / 0.6
		return 1.0 - (normalized * normalized)

func stop_drill():
	# prevent people from clicking the button multiple times
	if Globals.stopping:
		return
	
	Globals.stopping = true;

	if drill_move_tween:
		drill_move_tween.kill()
	if player_move_tween:
		player_move_tween.kill()
	if speed_tween:
		speed_tween.kill()
	
	var camera = get_tree().get_first_node_in_group("player").get_node("Camera2D")
	var player_node = get_tree().get_first_node_in_group("player")
	camera.offset = camera_base_offset
	
	var shop_layer = get_tree().current_scene.get_node_or_null("ShopLayer")
	if shop_layer and shop_layer.get_child_count() > 0:
		var shop = shop_layer.get_child(0)
		var fade_tween = create_tween()
		fade_tween.tween_property(shop, "modulate:a", 0.0, 0.5)
		fade_tween.tween_callback(shop_layer.queue_free)
	
	var particles = get_node_or_null("DrillParticles")
	if particles:
		particles.emitting = false
		get_tree().create_timer(1.0).timeout.connect(func(): 
			if particles and is_instance_valid(particles):
				particles.queue_free()
		)

	var min_speed = 0.3
	var max_speed = 3.0
	var duration = 3.5
	var anim_speed_tween = create_tween()
	anim_speed_tween.tween_method(func(t: float):
		var eased = ease_in_out_custom(t)
		speed_scale = lerp(min_speed, max_speed, eased)
	, 0.0, 1.0, duration)

	var final_tween = create_tween()
	final_tween.set_parallel(true)
		
	var goToY = 750;
	if Globals.level == 1:
		goToY = 1230
	elif Globals.level == 2:
		goToY = 2250
	
	final_tween.tween_property(self, "global_position:y", goToY, 3.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	final_tween.tween_property(player_node, "global_position:y", goToY, 3.7).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	
	# Pitch ramps up during fast descent
	var descent_duration = 3.5
	var pitch_tween = create_tween()
	pitch_tween.tween_property($drillSound, "pitch_scale", descent_peak_pitch, descent_pitch_ramp_up_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	# Schedule fade out + pitch return to start before descent ends
	var early_delay = max(descent_duration - sound_end_early_offset, 0.0)
	_start_sound_end_after(early_delay)
	
	await final_tween.finished
	
	# Stop shaking AFTER the descent ends
	is_shaking = false
	
	stop()
	miningParticles.emitting = false
	
	Globals.level += 1;


	if darkness_overlay:
		var dark_tween = create_tween()
		dark_tween.tween_property(darkness_overlay, "color:a", 0.0, 0.5)
		await dark_tween.finished
		
		if darkness_overlay:
			darkness_overlay.queue_free()
			darkness_overlay = null
	
	$drillSound.stop()
	$drillSound.pitch_scale = 1.0
	$drillSound.volume_db = 0.0
	
	var return_tween = create_tween()
	return_tween.set_parallel(true)
	return_tween.tween_property(camera, "offset", Vector2.ZERO, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	return_tween.tween_property(camera, "zoom", Vector2(1, 1), 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	await return_tween.finished
	
	camera_base_offset = Vector2.ZERO
	player_node.visible = true
	player_node.set_physics_process(true)
	z_index = 0
	speed_scale = 1.0
	show_gui_blocked = true
	started = false
	await get_tree().create_timer(1.0).timeout
	show_gui_blocked = false;
	Globals.stopping = false;
	Globals.inDrill = false;
	start_energy_fill()

func _start_sound_end_after(delay: float):
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	var sound_end_tween = create_tween()
	sound_end_tween.set_parallel(true)
	sound_end_tween.tween_property($drillSound, "pitch_scale", descent_return_pitch, descent_pitch_ramp_down_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	sound_end_tween.tween_property($drillSound, "volume_db", fadeout_target_volume_db, fadeout_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

func kill_all_enemies():
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.has_method("die"):
			enemy.die()
		await get_tree().create_timer(0.1).timeout

## ENERGYY

func start_energy_fill(duration: float = 15.0) -> void:
	energyFilled = false
	if Globals.bossAlive:
		$energyStaticIcon.visible = true
		$energyStaticIcon.play("waiting")
		_wait_for_boss_dead()
		return

	fade_in($energyIcon);
	$energyIcon.play();
	#$energyLabel.visible = true
	
	fade_in($energyBar);
	fade_in($energyIcon);
	$energyStaticIcon.visible = false
	$energyBar.value = 0

	var tween = create_tween()
	tween.tween_property($energyBar, "value", 100, duration)
	tween.tween_callback(_on_energy_fill_complete)

func _on_energy_fill_complete() -> void:
	$energyIcon.visible = false
	#$energyLabel.visible = false
	$energyBar.visible = false

	fade_in($energyStaticIcon)
	$energyStaticIcon.play("filled")
	energyFilled = true

func _wait_for_boss_dead() -> void:
	while Globals.bossAlive:
		await get_tree().create_timer(0.2).timeout
	_on_energy_fill_complete()

# halper function for nice lil animation
func fade_in(node: Node, duration: float = 0.3) -> Tween:
	node.modulate.a = 0.0
	node.visible = true
	var tween = create_tween()
	tween.tween_property(node, "modulate:a", 1.0, duration)
	return tween

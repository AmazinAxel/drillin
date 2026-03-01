extends AnimatedSprite2D
@onready var area = $Area2D
@onready var gui = $Label
@onready var player = get_parent().get_node("Player")
@onready var miningParticles = $miningParticles

var is_shaking = false
var darkness_overlay = null
var camera_base_offset = Vector2.ZERO
var drill_move_tween: Tween
var player_move_tween: Tween
var speed_tween: Tween
var trigger_distance := 50.0
var started = false
var show_gui_blocked = false

func _ready() -> void:
	print(gui)
	print(area)
	print(player)
	stop()

func _process(delta: float) -> void:
	if not player:
		return
	var dist = global_position.distance_to(player.global_position)
	
	if dist < trigger_distance and not started and not show_gui_blocked:
		gui.visible = true
		if Input.is_action_just_pressed("interact"):
			started = true
			gui.visible = false
			start_drill_sequence()
	else:
		gui.visible = false
	
	gui.scale.x = abs(gui.scale.x) * sign(scale.x)

func start_drill_sequence():
	play("default")
	
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
	
	is_shaking = true
	shake_camera_forever(camera)
	
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

func ease_in_out_custom(t: float) -> float:
	# Spends more time easing in, peaks around t=0.4, then eases out
	if t < 0.4:
		# Ease in (quadratic)
		var normalized = t / 0.4
		return normalized * normalized
	else:
		# Ease out (quadratic)
		var normalized = (t - 0.4) / 0.6
		return 1.0 - (normalized * normalized)

func stop_drill():
	if drill_move_tween:
		drill_move_tween.kill()
	if player_move_tween:
		player_move_tween.kill()
	if speed_tween:
		speed_tween.kill()
	
	var camera = get_tree().get_first_node_in_group("player").get_node("Camera2D")
	var player_node = get_tree().get_first_node_in_group("player")
	
	is_shaking = false
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

	# Custom eased animation speed: ramps up gradually then slows down
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
	final_tween.tween_property(self, "global_position:y", 700.0, 3.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	final_tween.tween_property(player_node, "global_position:y", 700.0, 3.7).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	await final_tween.finished
	
	stop()
	
	miningParticles.emitting = false
	
	if darkness_overlay:
		var dark_tween = create_tween()
		dark_tween.tween_property(darkness_overlay, "color:a", 0.0, 0.5)
		await dark_tween.finished
		darkness_overlay.queue_free()
		darkness_overlay = null
	
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
	show_gui_blocked = false

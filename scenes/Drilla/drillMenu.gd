extends AnimatedSprite2D
@onready var area = $Area2D
@onready var gui = $Label
@onready var player = get_parent().get_node("Player")

var is_shaking = false
var darkness_overlay = null
var camera_base_offset = Vector2.ZERO
var drill_move_tween: Tween
var player_move_tween: Tween
var speed_tween: Tween
var trigger_distance := 50.0
var started = false

func _ready() -> void:
	print(gui)
	print(area)
	print(player)
	play("default")

func _process(delta: float) -> void:
	if not player:
		return
	var dist = global_position.distance_to(player.global_position)
	
	if dist < trigger_distance:
		gui.visible = true
		if Input.is_action_just_pressed("interact") and not started:
			started = true
			gui.visible = false
			start_drill_sequence()
	else:
		gui.visible = false
	
	gui.scale.x = abs(gui.scale.x) * sign(scale.x)

func start_drill_sequence():
	var camera = get_tree().get_first_node_in_group("player").get_node("Camera2D")
	var player_node = get_tree().get_first_node_in_group("player")
	
	player_node.set_physics_process(false)
	player_node.visible = false  # hide player
	
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
	
	spawn_drill_particles()
	
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

func spawn_drill_particles():
	var particles = GPUParticles2D.new()
	particles.name = "DrillParticles"
	particles.amount = 20
	particles.lifetime = 0.8
	particles.position = Vector2(0, 20)
	
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.spread = 30.0
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0
	material.gravity = Vector3(0, 100, 0)
	material.scale_min = 1.0
	material.scale_max = 3.0
	material.color = Color(0.6, 0.4, 0.2, 1.0)
	
	particles.process_material = material
	add_child(particles)

func stop_drill():
	# Kill the long running tweens first
	if drill_move_tween:
		drill_move_tween.kill()
	if player_move_tween:
		player_move_tween.kill()
	if speed_tween:
		speed_tween.kill()
	
	var camera = get_tree().get_first_node_in_group("player").get_node("Camera2D")
	var player_node = get_tree().get_first_node_in_group("player")
	
	# Stop shaking but remember where we are
	is_shaking = false
	camera.offset = camera_base_offset  # lock at current base
	
	# Do everything at once - fade shop, move down, remove particles
	var shop_layer = get_tree().current_scene.get_node_or_null("ShopLayer")
	if shop_layer and shop_layer.get_child_count() > 0:
		var shop = shop_layer.get_child(0)
		var fade_tween = create_tween()
		fade_tween.tween_property(shop, "modulate:a", 0.0, 0.5)
		# Don't await - let it run alongside everything else
		fade_tween.tween_callback(shop_layer.queue_free)
	
	# Remove particles
	var particles = get_node_or_null("DrillParticles")
	if particles:
		particles.emitting = false
		# Clean up later, don't wait
		get_tree().create_timer(1.0).timeout.connect(func(): 
			if particles and is_instance_valid(particles):
				particles.queue_free()
		)

	# Lerp drill and player down to y=700 simultaneously
	var final_tween = create_tween()
	final_tween.set_parallel(true)
	final_tween.tween_property(self, "global_position:y", 700.0, 3.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	final_tween.tween_property(player_node, "global_position:y", 700.0, 3.7).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	await final_tween.finished
	
	# Fade out darkness
	if darkness_overlay:
		var dark_tween = create_tween()
		dark_tween.tween_property(darkness_overlay, "color:a", 0.0, 0.5)
		await dark_tween.finished
		darkness_overlay.queue_free()
		darkness_overlay = null
	
	# Smoothly animate camera back to center
	var return_tween = create_tween()
	return_tween.set_parallel(true)
	return_tween.tween_property(camera, "offset", Vector2.ZERO, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	return_tween.tween_property(camera, "zoom", Vector2(1, 1), 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	await return_tween.finished
	
	camera_base_offset = Vector2.ZERO
	player_node.visible = true  # show player
	player_node.set_physics_process(true)
	z_index = 0
	speed_scale = 1.0
	started = false

extends AnimatedSprite2D

@onready var area = $Area2D
@onready var gui = $Label
@onready var player = get_parent().get_node("Player")

func _ready() -> void:
	print(gui)
	print(area)
	print(player)
	play("default")
	
var trigger_distance := 50.0  # pixels
var started = false

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
	

	# Keep label from flipping with parent
	gui.scale.x = abs(gui.scale.x) * sign(scale.x)

func start_drill_sequence():
	var camera = get_tree().get_first_node_in_group("player").get_node("Camera2D")
	var player_node = get_tree().get_first_node_in_group("player")
	
	player_node.set_physics_process(false)
	
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.z_index = 10
	overlay.size = Vector2(9999, 9999)
	overlay.position = Vector2(-4999, -4999)
	get_tree().current_scene.add_child(overlay)
	
	z_index = 20
	
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.6, 1.0)
	
	shake_camera(camera, 4.0)
	
	await get_tree().create_timer(0.5).timeout
	
	# Synced movement - same distance, duration, and ease
# Synced movement
	var pan_distance = 300.0
	var pan_duration = 8.0
	var pan_ease = Tween.EASE_IN_OUT
	
	# Move drill down
	var drill_tween = create_tween()
	drill_tween.tween_property(self, "global_position:y", global_position.y + pan_distance, pan_duration).set_ease(pan_ease)
	
	# Move player down (camera follows automatically since it's a child)
	var player_tween = create_tween()
	player_tween.tween_property(player_node, "global_position:y", player_node.global_position.y + pan_distance, pan_duration).set_ease(pan_ease)
	
	var anim_tween = create_tween()
	anim_tween.tween_property(self, "speed_scale", 0.2, pan_duration)
	
	await get_tree().create_timer(pan_duration + 0.5).timeout
	
	var end_tween = create_tween()
	end_tween.tween_property(overlay, "color:a", 0.0, 1.0)
	await end_tween.finished
	overlay.queue_free()
	z_index = 0
	camera.offset.y = 0
	speed_scale = 1.0
	player_node.set_physics_process(true)
	started = false

func shake_camera(camera: Camera2D, duration: float):
	var shake_strength = 5.0
	var elapsed = 0.0
	while elapsed < duration:
		camera.offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		elapsed += get_process_delta_time()
		await get_tree().process_frame
	camera.offset = Vector2.ZERO

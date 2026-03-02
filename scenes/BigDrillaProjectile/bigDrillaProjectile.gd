extends CharacterBody2D

const SPEED = 200.0
var player: Node2D
var direction: Vector2 = Vector2.RIGHT
var homing: bool = false

func launch(dir: Vector2):
	direction = Vector2.UP
	rotation = direction.angle()
	
	await get_tree().create_timer(0.5).timeout
	if not is_instance_valid(self):
		return
	homing = true
	
	await get_tree().create_timer(0.5).timeout
	if not is_instance_valid(self):
		return
	homing = false

func _physics_process(delta):
	if homing:
		var p = get_tree().get_first_node_in_group("player")
		if p:
			direction = direction.lerp((p.global_position - global_position).normalized(), delta * 8).normalized()
			rotation = direction.angle()
	
	velocity = direction * SPEED
	move_and_slide()

func _ready():
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(self):
		queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		var p = get_tree().get_first_node_in_group("player")
		if p:
			p.take_damage(10)
		queue_free()

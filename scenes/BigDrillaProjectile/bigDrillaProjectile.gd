extends CharacterBody2D

const SPEED = 200.0
var player: Node2D
var returning := false
var direction: Vector2 = Vector2.RIGHT


func launch(dir: Vector2):
	direction = dir
	rotation = dir.angle()

func _physics_process(delta):
	velocity = direction * SPEED
	var collision = move_and_slide()
	
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(self):
		queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if body.name == "Player":
		if player:
			player.take_damage(10)
			queue_free()

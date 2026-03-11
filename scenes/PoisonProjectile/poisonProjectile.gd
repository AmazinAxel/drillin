extends CharacterBody2D

const SPEED = 200.0
var player: Node2D
var direction: Vector2 = Vector2.RIGHT
var homing: bool = false

func launch(dir: Vector2):
	direction = dir

func _physics_process(delta):
	velocity = direction * SPEED
	move_and_slide()
	
func _ready():
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(self):
		queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		var p = get_tree().get_first_node_in_group("player")
		if p:
			print("applied poison")
			PoisonManager.add_stack()
			p.take_damage(10)
		queue_free()
	elif body.name == "TileMapLayer":
		queue_free()
	

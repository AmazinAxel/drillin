extends CharacterBody2D

const SPEED = 300.0
const TARGET_DISTANCE = 10.0

var player: Node2D
var direction: Vector2 = Vector2.RIGHT
var homing: bool = false
var targetPosition: Vector2 
var isExploding: bool = false

@export var explosionScene: PackedScene
@export var targetScene: PackedScene


func launch(dir: Vector2):
	direction = Vector2.UP
	rotation = direction.angle()
	
	$MissileShot.playing = true
	
	var p = get_tree().get_first_node_in_group("player")
	if p:
		var target = targetScene.instantiate()
		get_tree().current_scene.add_child(target)
		target.global_position = p.global_position
		targetPosition = target.global_position
		
	await get_tree().create_timer(1).timeout
	if not is_instance_valid(self):
		return
	homing = true

func _physics_process(delta):
	if homing:
		direction = direction.lerp((targetPosition - global_position).normalized(), delta * 8).normalized()
		rotation = direction.angle()
		
		if global_position.distance_to(targetPosition) < TARGET_DISTANCE:
			createExplosion()
			return
	
	$MissileMoving.playing = true
	velocity = direction * SPEED
	move_and_slide()

func _ready():
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(self):
		queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		createExplosion()
	
	
func createExplosion():
	if is_instance_valid(self):
		if isExploding:
			return
		var explosion = explosionScene.instantiate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_position = global_position
		isExploding = true
		$Sprite2D.visible = false
		await get_tree().create_timer(1).timeout
		queue_free()

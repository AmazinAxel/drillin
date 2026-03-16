extends RigidBody2D

@onready var hitbox = $Hitbox
const SPEED = 500.0
var player: Node2D
var returning := false

func launch(dir: Vector2, from_player: Node2D):
	player = from_player
	gravity_scale = 0
	lock_rotation = true
	linear_velocity = dir * SPEED
	hitbox.disabled = false

func _physics_process(delta):
	rotation += deg_to_rad(20)
	
	if returning:
		hitbox.disabled = true
		var to_player = (player.global_position - global_position).normalized()
		linear_velocity = linear_velocity.lerp(to_player * SPEED * 1.5, delta * 5)
		
		if global_position.distance_to(player.global_position) < 40:
			player.catch_pickaxe()
			queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.name == "TileMapLayer" or body.name == "thrownPickaxe":
		return
	if body.has_method("take_damage"):
		if body.is_in_group("enemies")  && !returning:
			body.take_damage(round((Globals.attackDamage)/2), global_position)
		else:
			body.take_damage(round((Globals.attackDamage)/2))

	# RETURN AFTER HITTIN SOMETHING	
	#linear_velocity = Vector2.ZERO
	#gravity_scale = 0
	#await get_tree().create_timer(0.5).timeout
	#returning = true

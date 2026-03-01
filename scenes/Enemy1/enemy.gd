extends CharacterBody2D

var speed = 50.0
var health = 3
var gravity = 800.0
var jump_force = -300.0
var damage = 10
var can_damage = true

@onready var enemyWalkingAnimation = $AnimatedSprite2D 

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	enemyWalkingAnimation.play("default")
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * speed
		
		if player.global_position.y < global_position.y - 20 and is_on_floor():
			velocity.y = jump_force
		if is_on_wall() and is_on_floor():
			velocity.y = jump_force
		
		if direction.x > 0:
			$AnimatedSprite2D.flip_h = false
		elif direction.x < 0:
			$AnimatedSprite2D.flip_h = true
		
		# Damage player on contact
		var distance = global_position.distance_to(player.global_position)
		if can_damage and distance < 40:
			print("Hit player! Distance: ", distance)
			player.take_damage(damage)
			can_damage = false
			await get_tree().create_timer(1.0).timeout
			can_damage = true
	
	move_and_slide()

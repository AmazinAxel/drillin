extends CharacterBody2D

var speed = 50.0
var health = 3
var gravity = 800.0
var jump_force = -300.0

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Find player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var direction = (player.global_position - global_position).normalized()
		
		# Move horizontally toward player
		velocity.x = direction.x * speed
		
		# Jump if player is above and enemy is on the ground
		if player.global_position.y < global_position.y - 20 and is_on_floor():
			velocity.y = jump_force
		
		# Jump if there's a wall in the way
		if is_on_wall() and is_on_floor():
			velocity.y = jump_force
		
		# Flip sprite
		$AnimatedSprite2D.flip_h = direction.x < 0
	
	move_and_slide()

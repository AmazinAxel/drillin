extends CharacterBody2D

var speed = 50.0;
var health = 3;

func _physics_process(delta):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		
		$AnimatedSprite2D.flip_h = direction.x < 0

func take_damage(amount):
	health -= amount
	if health <= 0:
		queue_free()

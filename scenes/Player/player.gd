extends CharacterBody2D

@export var speed: float = 100.0
@export var acceleration: float = 50.0
@export var friction: float = 30.0

func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("left", "right", "up", "down")

	if direction != Vector2.ZERO:
		velocity = velocity.lerp(direction * speed, acceleration * delta)
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction * delta)
	
	
	move_and_slide()

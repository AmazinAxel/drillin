extends CharacterBody2D


const SPEED = 10
const JUMP_VELOCITY = -350.0

@onready var spotLight = $PointLight2D  # adjust path as needed

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = lerp(direction * SPEED, direction * SPEED * 2, 10)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	var mousePos = get_global_mouse_position()
	var lightDirection = (mousePos - global_position).angle()
	spotLight.rotation = lightDirection

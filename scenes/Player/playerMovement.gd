extends CharacterBody2D

const SPEED = 10
const JUMP_VELOCITY = -350.0

@onready var spotLight = $PointLight2D
@onready var health_bar = $TextureProgressBar
@onready var sprite = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("up") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = lerp(direction * SPEED, direction * SPEED * 2, 10)
		# Flip sprite based on direction
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()
	
	var mousePos = get_global_mouse_position()
	var lightDirection = (mousePos - global_position).angle()
	spotLight.rotation = lightDirection
	
	# Update health bar from global
	if health_bar:
		health_bar.value = Globals.health

func take_damage(amount):
	var actual_damage = amount * Globals.damageReduction
	Globals.health -= actual_damage
	Globals.health = max(Globals.health, 0)
	if health_bar:
		health_bar.value = Globals.health
	modulate = Color.RED
	await get_tree().create_timer(0.15).timeout
	modulate = Color.WHITE
	if Globals.health <= 0:
		get_tree().change_scene_to_file("res://scenes/DeathUI.tscn")

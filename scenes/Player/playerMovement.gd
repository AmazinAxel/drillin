extends CharacterBody2D

const SPEED = 10
const JUMP_VELOCITY = -350.0

@onready var health_bar = $TextureProgressBar
@onready var sprite = $AnimatedSprite2D
@onready var damageParticles = $damageParticles
@onready var walkingParticles = $walkingParticles
@onready var flashlight = $flashlight

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("up") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	var direction := Input.get_axis("left", "right")
	
	
	
	
	if direction:
		velocity.x = lerp(direction * SPEED, direction * SPEED * 2, 10)
		sprite.flip_h = direction > 0
		
		var lightDirection
		if direction > 0:
			lightDirection = 89.5
		else:
			lightDirection = -89.5
		flashlight.rotation = lightDirection
		
		sprite.play("default")
		walkingParticles.emitting = true
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		sprite.set_frame_and_progress(0, 0)
		sprite.pause()
		
	move_and_slide()
	
	#var mousePos = get_global_mouse_position()
	#var lightDirection = (mousePos - global_position).angle()
	
	if health_bar:
		health_bar.value = Globals.health

func take_damage(amount):
	var actual_damage = amount * Globals.damageReduction
	Globals.health -= actual_damage
	Globals.health = max(Globals.health, 0)
	damageParticles.emitting = true
	if health_bar:
		health_bar.value = Globals.health
	modulate = Color.RED
	await get_tree().create_timer(0.15).timeout
	modulate = Color.WHITE
	if Globals.health <= 0:
		get_tree().change_scene_to_file("res://scenes/DeathUI.tscn")
		Globals.health = 100;
		Globals.level = 1;
		Globals.damageReduction = 1;
		Globals.shootSpeed = 1;

		

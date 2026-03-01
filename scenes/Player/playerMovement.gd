extends CharacterBody2D

const SPEED = 10
const JUMP_VELOCITY = -350.0

@export var isAttacking: bool = false

@onready var health_bar = $TextureProgressBar
@onready var sprite = $AnimatedSprite2D

@onready var ohParticles = $ohParticles
@onready var ouchParticles = $ouchParticles
@onready var uhParticles = $uhParticles
@onready var unfriendlyOuchParticles = $unfriendlyOuchParticles

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
		
		if is_on_floor():
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
	
	var rand_int = randi_range(1, 4)
	
	if (rand_int == 1):
		ohParticles.emitting = true
	elif (rand_int == 2):
		uhParticles.emitting = true
	elif (rand_int == 3):
		ouchParticles.emitting = true
	elif (rand_int == 4):
		unfriendlyOuchParticles.emitting = true
		
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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and not isAttacking:
		attack()

func attack():
	if (self.name == "Player"):
		#var manager = get_node("/root/main/GameManager")
		#manager.lastDamageReason = "attack"
		#manager.health -= 5
		isAttacking = true
		#self.get_node("DamageSound").play()
		var timer = get_node("attackDelay");
		timer.start()


func _on_attack_delay_timeout() -> void:
	isAttacking = false 
	#var attackSprite = get_node("hurtBox/CollisionShape2D/Sprite2D")
	#attackSprite.visible = false

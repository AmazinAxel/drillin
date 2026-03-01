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
@onready var skullParticles = $skullParticles  # add this node

var is_dead := false

func _physics_process(delta: float) -> void:
	if is_dead:
		return  # stop all input/movement when dead
	
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
	
	if health_bar:
		health_bar.value = Globals.health

func take_damage(amount):
	if is_dead:
		return
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
		die()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	walkingParticles.emitting = false
	
	sprite.play("death")
	skullParticles.emitting = true
	
	# Wait 2 seconds then fade (no dependency on animation)
	get_tree().create_timer(2.0).timeout.connect(_on_death_timer_done, CONNECT_ONE_SHOT)

func _on_death_timer_done():
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.size = get_viewport().get_visible_rect().size
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.add_child(overlay)
	get_tree().root.add_child(canvas)
	
	var tween = get_tree().create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.5)
	tween.tween_callback(func():
		Globals.health = 100
		Globals.level = 1
		Globals.damageReduction = 1
		Globals.shootSpeed = 1
		get_tree().change_scene_to_file("res://scenes/UI/PlayUI.tscn")
		
		# Bind tween to overlay so it survives the scene change
		var tween2 = overlay.create_tween()
		tween2.tween_interval(0.1)
		tween2.tween_property(overlay, "color:a", 0.0, 0.5)
		tween2.tween_callback(canvas.queue_free)
	)

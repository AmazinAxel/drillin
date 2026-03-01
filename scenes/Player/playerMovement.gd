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

@onready var pickaxe = $pickaxe
@onready var pickaxeAttackArea = $pickaxe/damageArea

@export var thrown_pickaxe_scene: PackedScene  # assign in Inspector

var is_swinging: bool = false
var swing_tween: Tween
var baseRotation = 0
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
		pickaxe.flip_h = direction > 0
		pickaxe.flip_v = direction < 0
		
		
		var lightDirection
		if direction > 0:
			lightDirection = 89.5
			baseRotation = 0
		else:
			lightDirection = -89.5
			baseRotation = 30
			
		flashlight.rotation = lightDirection
		sprite.play("default")
		if is_on_floor():
			walkingParticles.emitting = true
			
		
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		sprite.set_frame_and_progress(0, 0)
		sprite.pause()
	
	move_and_slide()
	
	if !is_on_floor():
		sprite.play("jump")
		
	var mouse_pos = get_global_mouse_position()
	var mouseDirection = mouse_pos - global_position
	var angle = mouseDirection.angle()

	$pickaxe.rotation = angle + baseRotation
	var radius = 10 
	$pickaxe.position = Vector2.RIGHT.rotated(angle) * radius

	
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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and not isAttacking:
		attack()
	elif event.is_action_pressed("throw") and not isAttacking:
		throwPickaxe()
		
var thrown_instance = null

func throwPickaxe():
	if not thrown_pickaxe_scene:
		return
	if thrown_instance != null:  # already one in the air
		return

	pickaxe.visible = false
	isAttacking = true

	thrown_instance = thrown_pickaxe_scene.instantiate()
	get_tree().current_scene.add_child(thrown_instance)
	thrown_instance.global_position = pickaxe.global_position

	var dir = (get_global_mouse_position() - global_position).normalized()
	thrown_instance.rotation = dir.angle()
	thrown_instance.launch(dir, self)

	# After a short delay, start returning
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(thrown_instance):
		thrown_instance.returning = true

func catch_pickaxe():
	pickaxe.visible = true
	isAttacking = false
	thrown_instance = null

func attack():
	if (self.name == "Player"):
		isAttacking = true
		swing_pickaxe()
		var timer = get_node("attackDelay")
		timer.start()

func swing_pickaxe():
	if swing_tween:
		swing_tween.kill()
	
	swing_tween = create_tween()
	
	var current_angle = $pickaxe.rotation
	var swing_amount = deg_to_rad(90)
	
	if sprite.flip_h:
		swing_amount = -swing_amount
	
	# Enable damage during the swing
	pickaxeAttackArea.monitoring = true
	
	swing_tween.tween_property($pickaxe, "rotation", current_angle + swing_amount, 0.1)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_BACK)
	swing_tween.tween_property($pickaxe, "rotation", current_angle, 0.1)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_SINE)
	
	# Disable damage when swing ends
	swing_tween.tween_callback(func(): pickaxeAttackArea.monitoring = false)

func _on_attack_delay_timeout() -> void:
	isAttacking = false


func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		return
	elif body.name == "TileMapLayer":
		return

	if body.has_method("take_damage"):
		body.take_damage(Globals.attackDamage)

func die():
	is_dead = true
	velocity = Vector2.ZERO
	walkingParticles.emitting = false
	
	sprite.play("death")
	skullParticles.emitting = true
	
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
		Globals.level = 0;
		Globals.health = 100;
		Globals.damageReduction = 1;
		Globals.shootSpeed = 1;
		Globals.attackDamage = 1;
		Globals.minerals = 0;
		Globals.riskChance = 10;

		get_tree().change_scene_to_file("res://scenes/UI/PlayUI.tscn")

		var tween2 = overlay.create_tween()
		tween2.tween_interval(0.1)
		tween2.tween_property(overlay, "color:a", 0.0, 0.5)
		tween2.tween_callback(canvas.queue_free)
	)

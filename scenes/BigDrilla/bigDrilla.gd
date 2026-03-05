extends CharacterBody2D

@export var max_health: int = 50
@export var speed: float = 10.0
@export var animationSpeed: float = 100.0
@export var gravity: float = 400.0

@export var damage: int = 50
@export var damage_cooldown: float = 2.0

@export var attack_range: float = 60.0

@export var chargeDamage: int = 100
@export var charge_speed: float = 400.0
@export var charge_duration: float = 0.5

@export var projectile_scene: PackedScene

# === INTERNAL STATE ===
var health: int
var can_damage: bool = true
var is_charging: bool = false
var charge_direction: Vector2 = Vector2.ZERO
var isAnimatedIntoScene: bool = true

@onready var animated_sprite = $AnimatedSprite2D
@onready var health_bar = $TextureProgressBar
@onready var deathParticles = $deathParticles
@onready var drillSound = $drillSound
@onready var miningParticles = $miningParticles

func _ready():
	Globals.bossbar = 100
	
	health_bar.max_value = max_health
	health_bar.value = max_health
	
	isAnimatedIntoScene = true
	beginEnterAnimation()
	
	Globals.bossbar = max_health
	Globals.boss_health_changed.emit(max_health)
	
func beginEnterAnimation():
	var marker1 = get_tree().get_first_node_in_group("bossMarker1")
	var marker2 = get_tree().get_first_node_in_group("bossMarker2")
	var player = get_tree().get_first_node_in_group("player")
	
	if not player or not marker1 or not marker2:
		print("not found something")
		initReady()
		return
	
	var camera = player.get_node("Camera2D")
	
	var cam_tween = create_tween()
	cam_tween.set_ease(Tween.EASE_IN_OUT)
	cam_tween.set_trans(Tween.TRANS_CUBIC)
	cam_tween.tween_method(
		func(t): camera.global_position = camera.global_position.lerp(global_position, t),
		0.0, 1.0, 1.5
	)
	
	drillSound.play()
	
	miningParticles.emitting = true
	await _move_to(marker1.global_position, animationSpeed, camera)
	
	drillSound.stop()

	
	miningParticles.emitting = false
	await _move_to(marker2.global_position, animationSpeed, camera)
	
	var return_tween = create_tween()
	return_tween.set_ease(Tween.EASE_IN_OUT)
	return_tween.set_trans(Tween.TRANS_CUBIC)
	return_tween.tween_method(
		func(t): camera.global_position = camera.global_position.lerp(player.global_position, t),
		0.0, 1.0, 1.5
	)
	await return_tween.finished
	
	isAnimatedIntoScene = false
	initReady()

func _move_to(target: Vector2, move_speed: float, camera: Camera2D = null) -> void:
	
	while global_position.distance_to(target) > 5.0:
		var dir = (target - global_position).normalized()
		velocity.x = dir.x * move_speed
		velocity.y = dir.y * move_speed
		move_and_slide()
		animated_sprite.play("driving")
		
		if camera:
			camera.global_position = camera.global_position.lerp(global_position, 0.1)
		
		await get_tree().process_frame
	
	velocity = Vector2.ZERO
	
func initReady():
	collision_layer = 8
	collision_mask = 8
	shoot_loop()
	charge_loop()

func charge_loop():
	while is_instance_valid(self):
		await get_tree().create_timer(6.0).timeout
		start_charge()

func shoot_loop():
	while is_instance_valid(self):
		await get_tree().create_timer(randf_range(2.0, 5.0)).timeout
		await shoot_burst()

func shoot_burst():
	var burst_count = randi_range(3, 6) 
	for i in burst_count:
		shoot_projectile()
		await get_tree().create_timer(0.1).timeout

func shoot_projectile():
	if not projectile_scene:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position
	
	var dir = (player.global_position - global_position).normalized()
	var spread = deg_to_rad(randf_range(-15.0, 15.0))
	dir = dir.rotated(spread)
	
	projectile.launch(dir)

func start_charge():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	is_charging = true
	charge_direction = (player.global_position - global_position).normalized()
	await get_tree().create_timer(charge_duration).timeout
	is_charging = false

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	if isAnimatedIntoScene:
		return
		
	var player = get_tree().get_first_node_in_group("player")
	
	if is_charging:
		animated_sprite.play("driving") 
		velocity.x = charge_direction.x * charge_speed
		
		var distance = global_position.distance_to(player.global_position)
		if can_damage and distance < attack_range:
			player.take_damage(chargeDamage)
			can_damage = false
			await get_tree().create_timer(damage_cooldown).timeout
			can_damage = true

	elif player:
		animated_sprite.play("idle")
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * speed
		animated_sprite.flip_h = direction.x > 0

		var distance = global_position.distance_to(player.global_position)
		if can_damage and distance < attack_range:
			player.take_damage(damage)
			can_damage = false
			await get_tree().create_timer(damage_cooldown).timeout
			can_damage = true

	move_and_slide()

func take_damage(amount: int):
	health -= amount
	Globals.bossbar = health
	Globals.boss_health_changed.emit(health)
	if health <= 0:
		die()

func die():
	animated_sprite.play("death")
	deathParticles.emitting = true
	await get_tree().create_timer(1).timeout
	
	await get_tree().create_timer(1.0).timeout
	var shop_layer = CanvasLayer.new()
	shop_layer.layer = 100
	shop_layer.name = "ShopLayer"
	var shop = preload("res://scenes/UI/WinningUI.tscn").instantiate()
	shop.modulate = Color(1, 1, 1, 0)
	shop_layer.add_child(shop)
	get_tree().current_scene.add_child(shop_layer)
	
	var tween = shop.create_tween()
	tween.tween_property(shop, "modulate:a", 1.0, 0.5)
	
	queue_free()

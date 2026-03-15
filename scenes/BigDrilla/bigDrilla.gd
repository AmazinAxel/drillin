extends CharacterBody2D

@export var max_health: int = 40
@export var speed: float = 10.0
@export var animationSpeed: float = 100.0
@export var gravity: float = 400.0

@export var damage: int = 50
@export var damage_cooldown: float = 2.0

@export var chargeDamage: int = 20
@export var charge_speed: float = 300.0
@export var charge_duration: float = 0.5

@export var projectile_scene: PackedScene
@export var target_scene: PackedScene

# === RAGE STATE ===
var rage: float = 0.0 
var rage_build_rate: float = 0.01
var rage_decay_rate: float = 0.5

# === INTERNAL STATE ===
var health = max_health
var can_damage: bool = true
var is_charging: bool = false
var isDying: bool = false
var charge_direction: Vector2 = Vector2.ZERO
var isAnimatedIntoScene: bool = true

@onready var animated_sprite = $AnimatedSprite2D
@onready var deathParticles = $deathParticles
@onready var drillSound = $drillSound
@onready var miningParticles = $miningParticles
@onready var heatShieldEffect = $heatShieldEffect

func _ready():
	isAnimatedIntoScene = true
	heatShieldEffect.energy = 0.0
	beginEnterAnimation()
	Globals.bossAlive = true
	
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
	var originalZoom = camera.zoom
	var zoomedOut = originalZoom * 0.5
	cam_tween.tween_method(
		func(t): camera.zoom = originalZoom.lerp(zoomedOut, t),
		0.0, 1.0, 1.5
	)
	cam_tween.tween_method(
		func(t): camera.global_position = camera.global_position.lerp(global_position, t),
		0.0, 1.0, 1.5
	)
	
	drillSound.pitch_scale = 1.8
	drillSound.play()

	miningParticles.emitting = true
	await _move_to(marker1.global_position, animationSpeed, camera)
	
	drillSound.pitch_scale = 0.6

	miningParticles.emitting = false
	await _move_to(marker2.global_position, animationSpeed, camera)
	
	Globals.bossbarMaxValue = max_health
	var boss_layer = CanvasLayer.new()
	boss_layer.layer = 100
	boss_layer.name = "BossLayer"
	var bossLayer = preload("res://scenes/UI/BossUI.tscn").instantiate()
	bossLayer.modulate = Color(1, 1, 1, 0)
	boss_layer.add_child(bossLayer)
	get_tree().current_scene.add_child(boss_layer)
	
	var boss_tween = create_tween()
	boss_tween.tween_property(bossLayer, "modulate:a", 1.0, 1.0).set_ease(Tween.EASE_IN_OUT)
	Globals.boss_health_changed.emit(max_health)

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
	
func set_drill_pitch(target: float):
	var t = create_tween()
	t.tween_property(drillSound, "pitch_scale", target, 0.25).set_ease(Tween.EASE_IN_OUT)
	
func initReady():
	collision_layer = 8
	collision_mask = 8
	shoot_loop()
	charge_loop()
	
func charge_loop():
	while is_instance_valid(self) and not isDying:
		await get_tree().create_timer(5.0).timeout
		if isDying or not is_instance_valid(self):
			return
		var target = target_scene.instantiate()
		$WarningHolder.add_child(target)
		await get_tree().create_timer(1.0).timeout
		if isDying or not is_instance_valid(self):
			return
		start_charge()

func shoot_loop():
	while is_instance_valid(self):
		await get_tree().create_timer(randf_range(2.0, 5.0)).timeout
		await shoot_burst()

func shoot_burst():
	$PreparingMissile.playing = true
	await get_tree().create_timer(0.3).timeout
	var burst_count = randi_range(3, 6) 
	for i in burst_count:
		shoot_projectile()
		await get_tree().create_timer(0.3).timeout

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
	set_drill_pitch(1.8)
	
	var elapsed = 0.0
	while elapsed < charge_duration and is_charging:
		if not is_instance_valid(self):
			return
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		for i in get_slide_collision_count():
			var col = get_slide_collision(i)
			var normal = col.get_normal()
			if abs(normal.x) > 0.7:
				is_charging = false
				break
	
	is_charging = false
	if is_instance_valid(self):
		set_drill_pitch(0.6)

func get_rage_damage_multiplier() -> float:
	return 1.0 + rage * 2.0

func _physics_process(delta):
	if isDying:
		return
		
	if isAnimatedIntoScene:
		return
		
	if not is_on_floor():
		velocity.y += gravity * delta

	var player = get_tree().get_first_node_in_group("player")
	
	if is_charging:
		animated_sprite.play("driving")
		velocity.x = charge_direction.x * charge_speed
		rage = min(rage + rage_build_rate * 3.0 * 60.0, 1.0)
		
	elif player:
		animated_sprite.play("idle")
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * speed
		animated_sprite.flip_h = direction.x > 0
		
		if direction.x > 0:
			$DamageArea.rotation = 180
		else:
			$DamageArea.rotation = 0
			
		rage = max(rage - rage_decay_rate * delta * 60.0, 0.0)


	heatShieldEffect.energy = lerp(heatShieldEffect.energy, rage * 3.5, delta * 4.0)
	
	var lightDirection
	if player:
		if !is_charging:
			var direction = (player.global_position - global_position).normalized()
			if direction.x > 0:
				lightDirection = -89.5
			else:
				lightDirection = 89.5
			heatShieldEffect.rotation = lightDirection
		
	
	move_and_slide()

func take_damage(amount: int):
	health -= amount
	$BossHit.play()
	Globals.boss_health_changed.emit(health)
	if health <= 0:
		die()

func die():
	animated_sprite.play("death")
	deathParticles.emitting = true
	can_damage = false
	isDying = true
	$BossDeath1.playing = true
	await get_tree().create_timer(0.5).timeout
	animated_sprite.visible = false
	$BossDeath2.playing = true

	# Fade out the boss health bar
	var boss_layer = get_tree().current_scene.get_node_or_null("BossLayer")
	if boss_layer and boss_layer.get_child_count() > 0:
		var boss_ui = boss_layer.get_child(0)
		var fade_tween = create_tween()
		fade_tween.tween_property(boss_ui, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN_OUT)
		fade_tween.tween_callback(boss_layer.queue_free)

	await get_tree().create_timer(1).timeout
	
	#var shop_layer = CanvasLayer.new()
	#shop_layer.layer = 100
	#shop_layer.name = "ShopLayer"
	#var shop = preload("res://scenes/UI/WinningUI.tscn").instantiate()
	#shop.modulate = Color(1, 1, 1, 0)
	#shop_layer.add_child(shop)
	#get_tree().current_scene.add_child(shop_layer)
	
	#var tween = shop.create_tween()
	#tween.tween_property(shop, "modulate:a", 1.0, 0.5)
	
	queue_free()
	Globals.bossAlive = false
	Globals.boss1Time = Time.get_ticks_msec();


func _on_damage_area_body_entered(body: Node2D) -> void:

		if can_damage:
			var final_damage = int(chargeDamage * get_rage_damage_multiplier())
			
			var player = get_tree().get_first_node_in_group("player")
			if player:
				player.take_damage(final_damage)
			can_damage = false
			await get_tree().create_timer(damage_cooldown).timeout
			can_damage = true

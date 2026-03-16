extends CharacterBody2D

@export var max_health: int = 2
@export var speed: float = 100.0
@export var enragedSpeed: float = 150.0
@export var maxNumberOfBats: int = 3
@export var enragedMaxNumberOfBats: int = 5
var healthbar_thing;

@export var swarmDistance: float = 5
@export var animationSpeed: float = 150.0

@export var gravity: float = 800.0
@export var jump_force: float = -300.0
@export var damage: int = 50
@export var damage_cooldown: float = 1.0
@export var attack_range: float = 100.0

@export var knockbackFromPlayer: float = 1000.0
@export var knockbackForce: float = 3.0  


@export var dashSpeed: float = 300.0
@export var returnSpeed: float = 200.0
@export var dashTargetCount: int = 8
@export var dashTargetSpacing: float = 50.0
@export var target_scene: PackedScene


@export var attackDashSpeed: float = 450.0
@export var attackDashTargetCount: int = 30
@export var yLevelSpacing: int = 100

@export var batScenes: Array[PackedScene]

# === INTERNAL STATE ===
var health: int
var can_damage: bool = true
var isKnockedBackFromPlayer: bool = false
var knockbackVelocity: Vector2

var swarmOffset: Vector2 = Vector2.ZERO
var swarmOffsetTarget: Vector2 = Vector2.ZERO
var swarmOffsetTimer: float = 0.0
var dartVelocity: Vector2 = Vector2.ZERO
var overridePathfinding: bool = false

var yDifferenceInFloors: int = 0
var isLeftDirection: bool = false

var belowHalfHealth: bool = false
var isDashing: bool = false
var isAttackDashing: bool = false
var isDying: bool = false


var isAnimatedIntoScene: bool = true
@onready var animated_sprite = $AnimatedSprite2D

	
	
func _ready():
	isAnimatedIntoScene = true
	
	health = max_health
	
	beginEnterAnimation()
	Globals.bossAlive = true
	
func beginEnterAnimation():
	var player = get_tree().get_first_node_in_group("player")
		
	if not player:
		initReady()
		return
	
	var camera = player.get_node("Camera2D")
	
	var cam_tween = create_tween()
	cam_tween.set_ease(Tween.EASE_IN_OUT)
	cam_tween.set_trans(Tween.TRANS_CUBIC)
	var originalZoom = camera.zoom
	var zoomedOut = originalZoom *  0.5
	cam_tween.tween_method(
		func(t): camera.zoom = originalZoom.lerp(zoomedOut, t),
		0.0, 1.0, 1.5
	)
	cam_tween.tween_method(
		func(t): camera.global_position = camera.global_position.lerp(global_position, t),
		0.0, 1.0, 1.5
	)
	var spawnpoint = get_tree().get_first_node_in_group("mommaBatSpawnpoint")
	await moveToCenterWithCamera(spawnpoint.global_position, animationSpeed, camera)
	
	var return_tween = create_tween()
	return_tween.set_ease(Tween.EASE_IN_OUT)
	return_tween.set_trans(Tween.TRANS_CUBIC)
	return_tween.tween_method(
		func(t): camera.global_position = camera.global_position.lerp(player.global_position, t),
		0.0, 1.0, 1.5
	)
	await return_tween.finished
	
	Globals.bossbarMaxValue = max_health
	var boss_layer = CanvasLayer.new()
	boss_layer.layer = 100
	boss_layer.name = "BossLayer"
	var bossLayer = preload("res://scenes/BatBossUI/batBossUI.tscn").instantiate()
	bossLayer.modulate = Color(1, 1, 1, 0)
	boss_layer.add_child(bossLayer)
	get_tree().current_scene.add_child(boss_layer)
	
	var boss_tween = create_tween()
	boss_tween.tween_property(bossLayer, "modulate:a", 1.0, 1.0).set_ease(Tween.EASE_IN_OUT)
	Globals.boss_health_changed.emit(max_health)

	#healthbar_thing = bossLayer.get_node("healthbar");
	#healthbar_thing.texture_progress = preload("res://scenes/UI/BatBossBarAlivet.png");
	#healthbar_thing.texture_under = preload("res://scenes/UI/BatBossBarDedt.png");
	#bossLayer.get_node("bossName").visible = false; #text = "Momma Bat"
	
	Globals.bossbarMaxValue = max_health
	
	isAnimatedIntoScene = false
	initReady()

func moveToCenterWithCamera(target: Vector2, move_speed: float, camera: Camera2D = null) -> void:
	while global_position.distance_to(target) > 5.0:
		var dir = (target - global_position).normalized()
		velocity.x = dir.x * move_speed
		velocity.y = dir.y * move_speed
		animated_sprite.flip_h = velocity.x > 0
		move_and_slide()
		
		if camera:
			camera.global_position = camera.global_position.lerp(global_position, 0.1)
		
		await get_tree().process_frame
	
	velocity = Vector2.ZERO

func moveToPoint(target: Vector2, move_speed: float):
	while global_position.distance_to(target) > 5.0:
		
		if not is_instance_valid(self):
			return
			
		if isDying:
			return
			
		var dir = (target - global_position).normalized()
		velocity.x = dir.x * move_speed
		velocity.y = dir.y * move_speed
		animated_sprite.flip_h = velocity.x > 0
		
		if isDashing:
			var flipped = velocity.x > 0
			var offset = deg_to_rad(-25) if flipped else deg_to_rad(25)
			var angle = velocity.angle() + offset
			$DamageArea.rotation = angle
			$CollisionShape2D.rotation = angle
			
			if isAttackDashing:
				if flipped:
					$AnimatedSprite2D.rotation = angle + (deg_to_rad(25))
				else:
					$AnimatedSprite2D.rotation = angle + (deg_to_rad(155))
					
			else:
				if flipped:
					$AnimatedSprite2D.rotation = angle
				else:
					$AnimatedSprite2D.rotation = angle + (deg_to_rad(180))
					
		move_and_slide()
		await get_tree().process_frame
	
	velocity = Vector2.ZERO
	
func initReady():
	swarmOffsetTarget = Vector2(randf_range(-60, 60), randf_range(-80, 20))
	swarmOffset = swarmOffsetTarget
	
	diagonalDashLoop()
	startDashMode()

func diagonalDashLoop():
	while is_instance_valid(self):
		if belowHalfHealth:
			await get_tree().create_timer(0.1).timeout
			continue
		
		if isDying:
			return
			
		await spawnBats()
		await get_tree().create_timer(randf_range(3.0, 5.0)).timeout
		await startDiagonalDash()
		
func startDiagonalDash():
	
	if belowHalfHealth or isKnockedBackFromPlayer or isAnimatedIntoScene:
		return
	
	
	var player = get_tree().get_first_node_in_group("player")
	if not player or isKnockedBackFromPlayer or isAnimatedIntoScene:
		return

	var dir = (player.global_position - global_position).normalized()
	var lastTargetPos: Vector2
	
	for i in range(1, dashTargetCount + 1):
		var targetPos = global_position + dir * dashTargetSpacing * i
		var target = target_scene.instantiate()
		get_tree().current_scene.add_child(target)
		target.global_position = targetPos
		lastTargetPos = targetPos
	
	startDashingAnimation()
	await get_tree().create_timer(1).timeout

	overridePathfinding = true
	await moveToPoint(lastTargetPos, dashSpeed)
	
	stopDashingAnimation()
	var spawnpoint = get_tree().get_first_node_in_group("mommaBatSpawnpoint")
	await moveToPoint(spawnpoint.global_position, returnSpeed)
	
	overridePathfinding = false

func startDashMode():
	while is_instance_valid(self) and not isDying:
		if !belowHalfHealth:
			await get_tree().create_timer(0.1).timeout
			continue
		
		if not is_instance_valid(healthbar_thing):
			return
		healthbar_thing.texture_progress = preload("res://scenes/UI/BatBossBarAliveANNNNNGGGGRYYYYYYYYYY.png")

		await spawnBats()
		
		await get_tree().create_timer(randf_range(3.0, 5.0)).timeout
		
		if isDying:
			return
			
		isAttackDashing = true
		startDashingAnimation()
		overridePathfinding = true
		await moveToAttackPoints()
		
		for i in range(3):
			if isDying:
				return
			await moveToNextAttackPoints()
			if i < 2:
				await get_tree().create_timer(randf_range(0.5, 1.0)).timeout
		
		isAttackDashing = false
		stopDashingAnimation()
		await moveBackToSpawnpoint()
		overridePathfinding = false
		
		
		
func moveToAttackPoints():
	isLeftDirection = bool(randi() % 2)
	var currentFloor = randi_range(0, 3)
	yDifferenceInFloors = currentFloor * yLevelSpacing
	var animatePoint
	var animateDistance = 400
	if isLeftDirection:
		animateDistance *= -1
		var leftPoint = get_tree().get_first_node_in_group("attackPoint1")
		animatePoint = leftPoint
	else:
		animateDistance *= 1
		var rightPoint = get_tree().get_first_node_in_group("attackPoint2")
		animatePoint = rightPoint
	
	await moveToPoint(Vector2(global_position.x + animateDistance, global_position.y), attackDashSpeed)
	await moveToPoint(Vector2(animatePoint.global_position.x, animatePoint.global_position.y - yDifferenceInFloors), attackDashSpeed)

	
func moveToNextAttackPoints(): 
	var currentFloor = randi_range(0, 3)
	yDifferenceInFloors = currentFloor * yLevelSpacing
	
	var nextAnimatedPoint
	if isLeftDirection:
		var rightPoint = get_tree().get_first_node_in_group("attackPoint2")
		nextAnimatedPoint = rightPoint
	else:
		var leftPoint = get_tree().get_first_node_in_group("attackPoint1")
		nextAnimatedPoint = leftPoint
	
	var endAnimatedPointPos = Vector2(nextAnimatedPoint.global_position.x, nextAnimatedPoint.global_position.y - yDifferenceInFloors)

	for i in range(1, attackDashTargetCount + 1):
		var t = float(i) / float(dashTargetCount)
		var targetPos = global_position.lerp(endAnimatedPointPos, t)
		var target = target_scene.instantiate()
		get_tree().current_scene.add_child(target)
		target.global_position = targetPos
		
	await moveToPoint(endAnimatedPointPos, attackDashSpeed)
	isLeftDirection = !isLeftDirection
	
	
func moveBackToSpawnpoint():
	var animateDistance = 400
	
	if isLeftDirection:
		animateDistance *= -1
	else:
		animateDistance *= 1
	
	var spawnpoint = get_tree().get_first_node_in_group("mommaBatSpawnpoint")
	await moveToPoint(Vector2(spawnpoint.global_position.x + animateDistance, spawnpoint.global_position.y), attackDashSpeed)
	await moveToPoint(spawnpoint.global_position, attackDashSpeed)

func spawnBats():
	var numOfBats = randi_range(1, maxNumberOfBats)
	for i in range(numOfBats):
		if isDying:
			return
		var bat = batScenes.pick_random().instantiate()
		get_tree().current_scene.add_child(bat)
		bat.global_position = global_position
		await get_tree().create_timer(randf_range(0.5, 1.0)).timeout
		if isDying:
			return

func startDashingAnimation():
	isDashing = true
	$BatFlappingWings.playing = false
	$BossDashing.playing = true
	animated_sprite.play("dashing")
	
func stopDashingAnimation():
	isDashing = false
	$BatFlappingWings.playing = true
	$BossDashing.playing = false
	animated_sprite.play("default")
	$DamageArea.rotation = 25
	$CollisionShape2D.rotation = 25
	$AnimatedSprite2D.rotation = 0

func _physics_process(delta):
	if isAnimatedIntoScene:
		return
	
	if isDying:
		return
	
	if ((max_health / 2) > health) && !belowHalfHealth:
		belowHalfHealth = true
		
		speed = enragedSpeed
		maxNumberOfBats = enragedMaxNumberOfBats
		$BatBossEnraged.play()
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(animated_sprite, "modulate", Color("#ff3b2c"), 0.6)

	if overridePathfinding:
		return
		
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var distance = global_position.distance_to(player.global_position)
		
		swarmOffsetTimer -= delta
		if swarmOffsetTimer <= 0.0:
			swarmOffsetTimer = randf_range(0.8, 2.0)
			swarmOffsetTarget = Vector2(randf_range(-70, 70), randf_range(-90, 10))
		swarmOffset = swarmOffset.lerp(swarmOffsetTarget * swarmDistance, delta * 2.0)

		var desired_pos = player.global_position + swarmOffset
		var to_desired = (desired_pos - global_position)

		var desired_vel = to_desired.normalized() * speed

		if distance < attack_range * 1.5:
			var push_away = (global_position - player.global_position).normalized()
			desired_vel = push_away * speed * 1.5
		elif to_desired.length() < 20.0:
			desired_vel = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * speed * 0.3

		velocity = velocity.lerp(desired_vel, delta * 3.0)
		animated_sprite.flip_h = velocity.x > 0

	move_and_slide()


func take_damage(amount: int):
	health -= amount
	$BatBossDamage.play()
	Globals.boss_health_changed.emit(health)
	if health <= 0:
		die()
	

func die():
	overridePathfinding = true
	isDashing = false
	isDying = true
	velocity = Vector2.ZERO
	
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.4)
	
	for bat in get_tree().get_nodes_in_group("bats"):
		bat.queue_free()
	
	$BatBossDamage.play()
	animated_sprite.play("fallingDeath")
	
	var boss_layer = get_tree().current_scene.get_node_or_null("BossLayer")
	if boss_layer and boss_layer.get_child_count() > 0:
		var boss_ui = boss_layer.get_child(0)
		var fade_tween = create_tween()
		fade_tween.tween_property(boss_ui, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN_OUT)
		fade_tween.tween_callback(boss_layer.queue_free)

	while isDying == true:
		velocity.y += (gravity * 0.15) * get_process_delta_time()
		move_and_slide()
		if is_on_floor():
			isDying = false
		await get_tree().process_frame
			
	$DamageArea/CollisionShape2D.set_deferred("disabled", true)
	
	velocity = Vector2.ZERO
	animated_sprite.play("onGroundDeath")
	await animated_sprite.animation_finished
	
	await get_tree().create_timer(3.0).timeout
	queue_free()
	Globals.bossAlive = false;
	Globals.boss2Time = Time.get_ticks_msec();


func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		if can_damage == false:
			return
			
		body.take_damage(damage)
		can_damage = false
		await get_tree().create_timer(damage_cooldown).timeout
		can_damage = true
	elif body.name == "TileMapLayer":
		if isDying:
			isDying = false

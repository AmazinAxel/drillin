extends CharacterBody2D

@export var max_health: int = 6
@export var speed: float = 20.0
@export var dartSpeed: float = 2
@export var swarmDistance: float = 5
@export var animationSpeed: float = 150.0

@export var gravity: float = 800.0
@export var jump_force: float = -300.0
@export var damage: int = 10
@export var damage_cooldown: float = 1.0
@export var attack_range: float = 40.0

@export var knockbackFromPlayer: float = 1000.0
@export var knockbackForce: float = 3.0  

# === INTERNAL STATE ===
var health: int
var can_damage: bool = true
var isKnockedBackFromPlayer: bool = false
var knockbackVelocity: Vector2

var swarmOffset: Vector2 = Vector2.ZERO
var swarmOffsetTarget: Vector2 = Vector2.ZERO
var swarmOffsetTimer: float = 0.0
var dartVelocity: Vector2 = Vector2.ZERO
var isDarting: bool = false

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
	await _move_to(spawnpoint.global_position, animationSpeed, camera)
	
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
	swarmOffsetTarget = Vector2(randf_range(-60, 60), randf_range(-80, 20))
	swarmOffset = swarmOffsetTarget
	
	await get_tree().create_timer(randf_range(1.0, 3.0)).timeout
	dartLoop()
	
func dartLoop():
	while is_instance_valid(self):
		await get_tree().create_timer(randf_range(0.5, 3.0)).timeout
		_startDart()
		
func _startDart():
	var player = get_tree().get_first_node_in_group("player")
	if not player or isKnockedBackFromPlayer:
		return
		
	isDarting = true
	var dir = (player.global_position - global_position).normalized()
	dir = dir.rotated(randf_range(-0.9, 0.9))
	dartVelocity = dir * speed * randf_range(4.0, 7.0) * dartSpeed
	await get_tree().create_timer(0.2).timeout
	isDarting = false
	
func _physics_process(delta):
	if isAnimatedIntoScene:
		return
		
	if isKnockedBackFromPlayer:
		velocity.y += gravity * delta
		
	if isKnockedBackFromPlayer:
		knockbackVelocity = knockbackVelocity.lerp(Vector2.ZERO, delta * 10)
		velocity = knockbackVelocity
		if knockbackVelocity.length() < 10:
			knockbackVelocity = Vector2.ZERO
			isKnockedBackFromPlayer = false
		move_and_slide()
		return

	animated_sprite.play("default")
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		
		# Periodically drift the personal swarm offset to a new random spot
		swarmOffsetTimer -= delta
		if swarmOffsetTimer <= 0.0:
			swarmOffsetTimer = randf_range(0.8, 2.0)
			swarmOffsetTarget = Vector2(randf_range(-70, 70), randf_range(-90, 10))
		swarmOffset = swarmOffset.lerp(swarmOffsetTarget * swarmDistance, delta * 2.0)

		var desired_pos = player.global_position + swarmOffset
		var to_desired = (desired_pos - global_position)

		if isDarting:
			dartVelocity = dartVelocity.lerp(Vector2.ZERO, delta * 8.0)
			velocity = dartVelocity
		else:
			var desired_vel = to_desired.normalized() * speed
			if to_desired.length() < 20.0:
				desired_vel = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * speed * 0.3
			velocity = velocity.lerp(desired_vel, delta * 3.0)
			
			animated_sprite.flip_h = velocity.x > 0
				
			var distance = global_position.distance_to(player.global_position)
			if can_damage and distance < attack_range:
				player.take_damage(damage)
				var push_direction = (global_position - player.global_position).normalized()
				velocity.x = push_direction.x * speed * knockbackForce
				velocity.y = push_direction.y * speed * knockbackForce
				can_damage = false
				await get_tree().create_timer(damage_cooldown).timeout
				can_damage = true

	move_and_slide()



func take_damage(amount: int, hitFrom: Vector2 = Vector2.ZERO) -> void:
	health -= amount
	if hitFrom != Vector2.ZERO:
		var knockbackDir = (global_position - hitFrom).normalized()
		knockbackVelocity = knockbackDir * knockbackFromPlayer
		isKnockedBackFromPlayer = true
	
	if health <= 0:
		die()

func die():
	await get_tree().create_timer(0.2).timeout
	queue_free()

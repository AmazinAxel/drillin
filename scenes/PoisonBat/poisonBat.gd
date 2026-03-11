extends CharacterBody2D
@export var max_health: int = 6
@export var speed: float = 50.0
@export var swarmDistance: float = 1.3
@export var gravity: float = 800.0
@export var jump_force: float = -300.0
@export var damage: int = 10
@export var damage_cooldown: float = 1.0
@export var attack_range: float = 15.0
@export var knockbackFromPlayer: float = 1000.0
@export var knockbackForce: float = 3.0
@export var shoot_range: float = 200.0
@export var shoot_cooldown: float = 1.5


@export var projectileScene: PackedScene

# === INTERNAL STATE ===
var health: int
var can_damage: bool = true
var isKnockedBackFromPlayer: bool = false
var knockbackVelocity: Vector2
var swarmOffset: Vector2 = Vector2.ZERO
var swarmOffsetTarget: Vector2 = Vector2.ZERO
var swarmOffsetTimer: float = 0.0
var shoot_timer: float = 0.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var health_bar = $TextureProgressBar

func _ready():
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = max_health
	
	swarmOffsetTarget = Vector2(randf_range(-60, 60), randf_range(-80, 20))
	swarmOffset = swarmOffsetTarget
	

func shoot_projectile():
	if not projectileScene:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	var projectile = projectileScene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position
	
	var dir = (player.global_position - global_position).normalized()
	var spread = deg_to_rad(randf_range(-5.0, 5.0))
	dir = dir.rotated(spread)
	
	projectile.launch(dir)
	
func _physics_process(delta):
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
			
		if can_damage and distance < attack_range:
			player.take_damage(damage)
			var push_direction = (global_position - player.global_position).normalized()
			velocity.x = push_direction.x * speed * knockbackForce
			velocity.y = push_direction.y * speed * knockbackForce
			can_damage = false
			await get_tree().create_timer(damage_cooldown).timeout
			can_damage = true
		
		if distance < shoot_range:
			shoot_timer -= delta
			if shoot_timer <= 0.0:
				shoot_timer = shoot_cooldown
				shoot_projectile()

	move_and_slide()
	

func take_damage(amount: int, hitFrom: Vector2 = Vector2.ZERO) -> void:
	health -= amount
	health_bar.value = health
	if hitFrom != Vector2.ZERO:
		var knockbackDir = (global_position - hitFrom).normalized()
		knockbackVelocity = knockbackDir * knockbackFromPlayer
		isKnockedBackFromPlayer = true
	
	if health <= 0:
		$EnemyDeathSound.playing = true
		die()
	else:
		$EnemyHitSound.playing = true

func die():
	await get_tree().create_timer(0.2).timeout
	queue_free()

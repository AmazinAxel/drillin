extends CharacterBody2D

@export var max_health: int = 6
@export var speed: float = 50.0
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

@onready var animated_sprite = $AnimatedSprite2D
@onready var health_bar = $TextureProgressBar

func _ready():
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = max_health
	
	swarmOffsetTarget = Vector2(randf_range(-60, 60), randf_range(-80, 20))
	swarmOffset = swarmOffsetTarget
	
	await get_tree().create_timer(randf_range(0.5, 3.0)).timeout
	dartLoop()

func dartLoop():
	while is_instance_valid(self):
		await get_tree().create_timer(randf_range(1.5, 4.0)).timeout
		_startDart()
		
func _startDart():
	var player = get_tree().get_first_node_in_group("player")
	if not player or isKnockedBackFromPlayer:
		return
		
	isDarting = true
	var dir = (player.global_position - global_position).normalized()
	dir = dir.rotated(randf_range(-0.4, 0.4))
	dartVelocity = dir * speed * randf_range(4.0, 7.0)
	await get_tree().create_timer(0.2).timeout
	isDarting = false
	
func _physics_process(delta):
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
		swarmOffset = swarmOffset.lerp(swarmOffsetTarget, delta * 2.0)

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
	health_bar.value = health
	if hitFrom != Vector2.ZERO:
		var knockbackDir = (global_position - hitFrom).normalized()
		knockbackVelocity = knockbackDir * knockbackFromPlayer
		isKnockedBackFromPlayer = true
	
	if health <= 0:
		die()

func die():
	await get_tree().create_timer(0.2).timeout
	queue_free()

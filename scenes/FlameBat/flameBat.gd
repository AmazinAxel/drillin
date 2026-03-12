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
@export var flames_visible_range: float = 80.0
@export var flame_damage: int = 5
@export var flame_damage_interval: float = 0.1

# === INTERNAL STATE ===
var health: int
var can_damage: bool = true
var isKnockedBackFromPlayer: bool = false
var knockbackVelocity: Vector2
var swarmOffset: Vector2 = Vector2.ZERO
var swarmOffsetTarget: Vector2 = Vector2.ZERO
var swarmOffsetTimer: float = 0.0
var flame_damage_timer: float = 0.0
var flameIsVisible: bool = false
var playerIsInFlames: bool = false

@onready var animated_sprite = $AnimatedSprite2D
@onready var health_bar = $TextureProgressBar
@onready var flames = $Flames

func _ready():
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = max_health
	
	swarmOffsetTarget = Vector2(randf_range(-60, 60), randf_range(-80, 20))
	swarmOffset = swarmOffsetTarget
	flames.visible = false

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
		
		flameIsVisible = distance <= flames_visible_range
		flames.visible = flameIsVisible
		flames.look_at(player.global_position)

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
	
	if flameIsVisible:
		if !$Flame.playing:
			$Flame.playing = true
			

		var flame_dir = (player.global_position - global_position).angle()
		var flame_deg = (rad_to_deg(flame_dir) * -1) + 180
		$Flames/FlameParticles.angle_min = flame_deg
		$Flames/FlameParticles.angle_max = flame_deg
		
		flame_damage_timer -= delta
		if flame_damage_timer <= 0.0:
			flame_damage_timer = flame_damage_interval
			if playerIsInFlames:
				player.take_damage(flame_damage)
	else:
		$Flame.playing = false

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


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and !playerIsInFlames:
		playerIsInFlames = true
		flame_damage_timer = 0.0

func _on_area_2d_body_exited(body: Node2D) -> void:
	playerIsInFlames = false

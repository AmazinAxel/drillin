extends CharacterBody2D
@export var jump_force: float = -300.0

@export var max_health: int = 6
@export var speed: float = 40.0
@export var gravity: float = 400.0
@export var jump_threshold: float = 20.0  # How far above the enemy the player must be to trigger a jump

@export var knockbackFromPlayer: float = 300.0

@export var damage: int = 50
@export var damage_cooldown: float = 0.5

@export var attack_range: float = 60.0
@export var projectile_scene: PackedScene

# === INTERNAL STATE ===
var health: int
var can_damage: bool = true

var isKnockedBackFromPlayer: bool = false
var knockbackVelocity: Vector2

@onready var animated_sprite = $AnimatedSprite2D
@onready var health_bar = $TextureProgressBar
@onready var deathParticles = $deathParticles

func _ready():
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = max_health
	
	await get_tree().create_timer(randf_range(0.0, 2.0)).timeout
	animated_sprite.play("shoot")
	shoot_loop()

func shoot_loop():
	while is_instance_valid(self):
		await get_tree().create_timer(randf_range(3.0, 6.0)).timeout
		await shoot_burst()

func shoot_burst():
	var burst_count = randi_range(1, 2) 
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


func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
		
	if isKnockedBackFromPlayer:
		knockbackVelocity = knockbackVelocity.lerp(Vector2.ZERO, delta * 10)
		velocity = knockbackVelocity
		if knockbackVelocity.length() < 10:
			knockbackVelocity = Vector2.ZERO
			isKnockedBackFromPlayer = false
			
	var player = get_tree().get_first_node_in_group("player")
	if player && !isKnockedBackFromPlayer:
		animated_sprite.play("default")
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * speed
		animated_sprite.flip_h = direction.x > 0

		var distance = global_position.distance_to(player.global_position)
		if can_damage and distance < attack_range:
			player.take_damage(damage)
			can_damage = false
			await get_tree().create_timer(damage_cooldown).timeout
			can_damage = true
			
		# Jump if player is above or if stuck against a wall
		if player.global_position.y < global_position.y - jump_threshold and is_on_floor():
			velocity.y = jump_force

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
	deathParticles.emitting = true
	await get_tree().create_timer(0.2).timeout
	queue_free()

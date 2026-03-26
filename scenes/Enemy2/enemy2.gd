extends CharacterBody2D

var max_health: int = 6
var speed: float = 60.0
var gravity: float = 800.0
var jump_force: float = -300.0
var damage: int = 8
var damage_cooldown: float = 1.0
var attack_range: float = 40.0
var jump_threshold: float = 20.0  # How far above the enemy the player must be to trigger a jump
var knockbackFromPlayer: float = 200.0

var health: int
var can_damage: bool = true
var isKnockedBackFromPlayer: bool = false
var knockbackVelocity: Vector2

func _ready():
	add_to_group("enemies")
	health = max_health
	$TextureProgressBar.max_value = max_health
	$TextureProgressBar.value = max_health

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if isKnockedBackFromPlayer:
		knockbackVelocity = knockbackVelocity.lerp(Vector2.ZERO, delta * 10)
		velocity = knockbackVelocity
		if knockbackVelocity.length() < 10:
			knockbackVelocity = Vector2.ZERO
			isKnockedBackFromPlayer = false
			
	$AnimatedSprite2D.play("default")
	var player = get_tree().get_first_node_in_group("player")
	if player && !isKnockedBackFromPlayer:
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * speed

		if player.global_position.y < global_position.y - jump_threshold and is_on_floor():
			velocity.y = jump_force
		if is_on_wall() and is_on_floor():
			velocity.y = jump_force

		if direction.x > 0:
			$AnimatedSprite2D.flip_h = false
		elif direction.x < 0:
			$AnimatedSprite2D.flip_h = true

		var distance = global_position.distance_to(player.global_position)
		if can_damage and distance < attack_range:
			player.take_damage(damage)
			can_damage = false
			await get_tree().create_timer(damage_cooldown).timeout
			can_damage = true

	move_and_slide()

func take_damage(amount: int, hitFrom: Vector2 = Vector2.ZERO) -> void:
	health -= amount
	$TextureProgressBar.value = health
	
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
	$deathParticles.emitting = true
	await get_tree().create_timer(0.2).timeout
	queue_free()

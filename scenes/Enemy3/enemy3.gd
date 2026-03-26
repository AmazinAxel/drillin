extends CharacterBody2D

var jump_force: float = -300.0
var max_health: int = 4
var speed: float = 40.0
var gravity: float = 400.0
var jump_threshold: float = 20.0 
var knockbackFromPlayer: float = 300.0
var damage: int = 5
var damage_cooldown: float = 0.5
var attack_range: float = 60.0
@export var projectile_scene: PackedScene # THIS IS AN EXPORT DO NOT REMOVE

var minAttackDistance: float = 100.0 
var maxAttackDistance: float = 150.0 

var health: int
var can_damage: bool = true
var isKnockedBackFromPlayer: bool = false
var knockbackVelocity: Vector2

func _ready():
	health = max_health
	$TextureProgressBar.max_value = max_health
	$TextureProgressBar.value = max_health
	
	await get_tree().create_timer(randf_range(0.0, 2.0)).timeout
	$AnimatedSprite2D.play("shoot")
	shoot_loop()

func shoot_loop():
	while is_instance_valid(self):
		await get_tree().create_timer(randf_range(1.0, 2.5)).timeout
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
		$AnimatedSprite2D.play("default")
		var direction = (player.global_position - global_position).normalized()
		
		var distance = global_position.distance_to(player.global_position)
		if distance < minAttackDistance:
			velocity.x = -direction.x * speed
		elif distance > maxAttackDistance:
			velocity.x = direction.x * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			
		$AnimatedSprite2D.flip_h = direction.x > 0

			
		if player.global_position.y < global_position.y - jump_threshold and is_on_floor():
			velocity.y = jump_force

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

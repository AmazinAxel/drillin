extends CharacterBody2D

# configure
var max_health: int = 6
var speed: float = 50.0
var swarmDistance: float = 1.3
var gravity: float = 800.0
var jump_force: float = -300.0
var damage: int = 5
var damage_cooldown: float = 1.0
var attack_range: float = 15.0
var knockbackFromPlayer: float = 1000.0
var knockbackForce: float = 3.0
var flamesVisibleRange: float = 200.0
var flameDamage: int = 5
var flameDamageInterval: float = 0.1
var flameColliderMaxWidth: float = 60.0
var flameGrowSpeed: float = 3.0
var flameRotationSpeed: float = 2.0

var health: int
var can_damage: bool = true
var isKnockedBackFromPlayer: bool = false
var knockbackVelocity: Vector2
var swarmOffset: Vector2 = Vector2.ZERO
var swarmOffsetTarget: Vector2 = Vector2.ZERO
var swarmOffsetTimer: float = 0.0
var flameDamageTimer: float = 0.0
var flameIntensity: float = 0.0
var flameIsVisible: bool = false
var playerIsInFlames: bool = false

@onready var flameCollider = $Flames/CollisionShape2D
 
func _ready():
	health = max_health
	$TextureProgressBar.max_value = max_health
	$TextureProgressBar.value = max_health
	
	swarmOffsetTarget = Vector2(randf_range(-60, 60), randf_range(-80, 20))
	swarmOffset = swarmOffsetTarget
	
	$Flames.visible = true
	$Flames/FlameParticles.emitting = false
	_apply_flame_intensity(0.0)

func _physics_process(delta):
	if isKnockedBackFromPlayer:
		knockbackVelocity = knockbackVelocity.lerp(Vector2.ZERO, delta * 10)
		velocity = knockbackVelocity
		if knockbackVelocity.length() < 10:
			knockbackVelocity = Vector2.ZERO
			isKnockedBackFromPlayer = false
		move_and_slide()
		return
		
	$AnimatedSprite2D.play("default")
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var distance = global_position.distance_to(player.global_position)
		
		flameIsVisible = (distance <= flamesVisibleRange and hasLineOfSightToPlayer(player))
		var intensityTarget = 1.0 if flameIsVisible else 0.0
		flameIntensity = move_toward(flameIntensity, intensityTarget, delta * flameGrowSpeed)
		_apply_flame_intensity(flameIntensity)

		var targetAngle = (player.global_position - global_position).angle()
		var angleDiff = angle_difference($Flames.rotation, targetAngle)
		$Flames.rotation += move_toward(0.0, angleDiff, flameRotationSpeed * delta)
		
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
		$AnimatedSprite2D.flip_h = velocity.x > 0
			
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
			
			
		var flame_deg = (rad_to_deg($Flames.rotation) * -1) + 180
		
		$Flames/FlameParticles.angle_min = flame_deg
		$Flames/FlameParticles.angle_max = flame_deg
		
		flameDamageTimer -= delta
		if flameDamageTimer <= 0.0:
			flameDamageTimer = flameDamageInterval
			if playerIsInFlames:
				player.take_damage(flameDamage)
	else:
		$Flame.playing = false

	move_and_slide()

func _apply_flame_intensity(t: float) -> void:
	$Flames/FlameParticles.emitting = t > 0.0
 
	if $Flames/CollisionShape2D and $Flames/CollisionShape2D.shape is RectangleShape2D:
		var base_height = $Flames/CollisionShape2D.shape.size.x
		$Flames/CollisionShape2D.shape.size.x = flameColliderMaxWidth * t
		
func hasLineOfSightToPlayer(player: Node2D) -> bool:
	var space = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position)
	query.exclude = [self]
	var result = space.intersect_ray(query)
	
	if result.is_empty():
		return true 
	
	var collider = result.get("collider")
	if collider and collider.name == "TileMapLayer":
		return false
	
	return true
	
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
	await get_tree().create_timer(0.2).timeout
	queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and !playerIsInFlames:
		playerIsInFlames = true
		flameDamageTimer = 0.0

func _on_area_2d_body_exited(body: Node2D) -> void:
	playerIsInFlames = false

extends CharacterBody2D

@export var max_health: int = 3
@export var speed: float = 10.0
@export var gravity: float = 400.0

@export var damage: int = 50
@export var damage_cooldown: float = 2.0

@export var attack_range: float = 60.0

@export var chargeDamage: int = 100
@export var charge_speed: float = 400.0
@export var charge_duration: float = 0.5
@export var projectile_scene: PackedScene

# === INTERNAL STATE ===
var health: int
var can_damage: bool = true
var is_charging: bool = false
var charge_direction: Vector2 = Vector2.ZERO

@onready var animated_sprite = $AnimatedSprite2D
@onready var health_bar = $TextureProgressBar
@onready var deathParticles = $deathParticles

func _ready():
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = max_health
	
	await get_tree().create_timer(randf_range(0.0, 10.0)).timeout
	charge_loop()
	
	await get_tree().create_timer(randf_range(0.0, 5.0)).timeout
	shoot_loop()

func charge_loop():
	while is_instance_valid(self):
		await get_tree().create_timer(5.0).timeout
		start_charge()

func shoot_loop():
	while is_instance_valid(self):
		await get_tree().create_timer(randf_range(3.0, 6.0)).timeout
		await shoot_burst()

func shoot_burst():
	var burst_count = randi_range(3, 6) 
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

func start_charge():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	is_charging = true
	charge_direction = (player.global_position - global_position).normalized()
	await get_tree().create_timer(charge_duration).timeout
	is_charging = false

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	var player = get_tree().get_first_node_in_group("player")
	
	if is_charging:
		animated_sprite.play("driving") 
		velocity.x = charge_direction.x * charge_speed
		
		var distance = global_position.distance_to(player.global_position)
		if can_damage and distance < attack_range:
			player.take_damage(chargeDamage)
			can_damage = false
			await get_tree().create_timer(damage_cooldown).timeout
			can_damage = true

	elif player:
		animated_sprite.play("idle")
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * speed
		animated_sprite.flip_h = direction.x > 0

		var distance = global_position.distance_to(player.global_position)
		if can_damage and distance < attack_range:
			player.take_damage(damage)
			can_damage = false
			await get_tree().create_timer(damage_cooldown).timeout
			can_damage = true

	move_and_slide()

func take_damage(amount: int):
	health -= amount
	health_bar.value = health
	if health <= 0:
		die()
	
func die():
	animated_sprite.play("death")
	deathParticles.emitting = true
	await get_tree().create_timer(1).timeout
	
	var win_ui = get_tree().current_scene.get_node("WinningUI")
	if win_ui:
		win_ui.visible = true
	
	queue_free()

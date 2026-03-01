extends CharacterBody2D

@export var max_health: int = 3
@export var speed: float = 10.0
@export var gravity: float = 400.0
@export var jump_force: float = -200.0
@export var damage: int = 10
@export var damage_cooldown: float = 1.0
@export var attack_range: float = 40.0
@export var jump_threshold: float = 20.0 

# === INTERNAL STATE ===
var health: int
var can_damage: bool = true

@onready var animated_sprite = $AnimatedSprite2D
@onready var health_bar = $TextureProgressBar

func _ready():
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = max_health

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	animated_sprite.play("default")

	var player = get_tree().get_first_node_in_group("player")
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * speed

		if player.global_position.y < global_position.y - jump_threshold and is_on_floor():
			velocity.y = jump_force
		if is_on_wall() and is_on_floor():
			velocity.y = jump_force

		if direction.x > 0:
			animated_sprite.flip_h = false
		elif direction.x < 0:
			animated_sprite.flip_h = true

		# Damage player on contact
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
	queue_free()

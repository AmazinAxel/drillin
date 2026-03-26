extends StaticBody2D

var max_health: float = 6.0 # config
var mineral_reward: int = 2 # config
var health: float
var is_pickup: bool = false
var speed: float = 0.0
var max_speed: float = 300.0
var acceleration: float = 600.0
var target: Node2D = null
var bob_time: float = 0.0

func _ready():
	health = max_health
	$TextureProgressBar.max_value = max_health
	$TextureProgressBar.value = max_health
	$TextureProgressBar.visible = false
	$UI.visible = false

func take_damage(amount):
	if amount == null:
		return
	health -= amount
	health = max(health, 0)
	
	if randf() < 0.5:
		$hit.play()
	else:
		$hit2.play()

	$TextureProgressBar.visible = true
	$TextureProgressBar.value = health
	$UI.visible = true
	$damageParticles.emitting = true

	modulate = Color.WHITE * 2
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE

	if health <= 0:
		_become_pickup()

func _become_pickup():
	is_pickup = true

	# Hide health bar and disable collision
	$TextureProgressBar.visible = false
	$UI.visible = false
	$CollisionShape2D.set_deferred("disabled", true)

	# Shrink and float up
	scale = Vector2(0.5, 0.5)
	global_position.y -= 10

	# Find player after brief pause
	await get_tree().create_timer(0.3).timeout
	target = get_tree().get_first_node_in_group("player")


func _process(delta):
	if not is_pickup:
		return

	if target and is_instance_valid(target):
		speed = min(speed + acceleration * delta, max_speed)
		var dir = (target.global_position - global_position).normalized()
		global_position += dir * speed * delta

		if global_position.distance_to(target.global_position) < 15:
			Globals.minerals += mineral_reward
			target.playPickupSound()
			mainHUD.setMinerals(Globals.minerals);
			queue_free()
	else:
		bob_time += delta
		global_position.y += sin(bob_time * 3.0) * 0.5

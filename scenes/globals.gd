extends Node

var level
var health
var damageReduction
var shootSpeed
var attackDamage
var minerals
var riskChance
var isAttacking
var baseRotation
var isDead
var stopping
var inDrill
var bossbarMaxValue = 100 # doesnt need to have reset vaule since its overwritten by default
var bossAlive
var lives = 9;

func _ready():
	resetVars()

func resetVars():
	level = 6
	health = 100
	damageReduction = 1
	shootSpeed = 1
	attackDamage = 2
	minerals = 0
	riskChance = 10
	isAttacking = false
	baseRotation = 0
	isDead = false
	stopping = false
	inDrill = false
	bossAlive = false


func screen_shake(strength: float, duration: float):
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return # could prevent errors idk

	var tween = create_tween()
	tween.tween_method(func(t):
		camera.offset = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
	, 0.0, 1.0, duration)
	tween.tween_callback(func(): camera.offset = Vector2.ZERO)

# bossbar
signal boss_health_changed(value)

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
var started = false;
var checkpoint = 0
var startTime = Time.get_ticks_msec();
var boss1Time;
var boss2Time;
#var boss3Time;
var checkpointMinerals = 0;
var checkpointDamageUpgrade = 0;
var checkpointReplenishCount = 0;

var damageUpgradeCount
var armorUpgradeCount
var replenishCount

func _ready():
	resetVars()

func resetVars():
	var startTime = Time.get_ticks_msec();
	level = 2
	health = 100
	damageReduction = 1
	shootSpeed = 1
	attackDamage = 2
	checkpoint = 0

	minerals = 0
	lives = 9
	riskChance = 10
	isAttacking = false
	baseRotation = 0
	isDead = false
	stopping = false
	inDrill = false
	bossAlive = false
	# does NOT reset starting
	
	damageUpgradeCount = 0
	replenishCount = 0
	armorUpgradeCount = 0
	boss1Time = null;
	boss2Time = null;
	checkpointMinerals = 0;
	checkpointDamageUpgrade = 0;
	checkpointReplenishCount = 0;

	#boss3Time = null;

func permDie():
	resetVars()
	level = 0
	

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

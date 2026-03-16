extends Node

var level
var health
var damageReduction
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
var lives;
var showUI = false;
var checkpoint;
var started = false
var startTime = Time.get_ticks_msec();
var boss1Time;
var boss2Time;
var checkpointLevel;
var transitioningOut;
#var boss3Time;
var checkpointMinerals = 0;
var checkpointDamageUpgradeCount = 0;
var checkpointReplenishCount = 0;
var checkpointArmorUpgradeCount = 0;
var checkpointDamageReduction
var checkpointAttackDamage
			

var damageUpgradeCount
var armorUpgradeCount
var replenishCount


func _ready():
	resetVars()

func resetVars():
	startTime = Time.get_ticks_msec();
	level = 0
	health = 100
	damageReduction = 1
	attackDamage = 2
	checkpoint = 0
	# checkpoint level not set

	minerals = 0
	lives = 10
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
	armorUpgradeCount = 0;
	transitioningOut = false;
	boss1Time = null;
	boss2Time = null;
	#checkpointMinerals = 0; # DONT USE THIS 
	#checkpointAttackDamage = 0;
	#checkpointReplenishCount = 0;

	#boss3Time = null;


func resetToSpawnpoint():
	minerals = checkpointMinerals;
	damageReduction = checkpointDamageReduction;
	attackDamage = checkpointAttackDamage;
	level = checkpointLevel;
	
	# count stuff
	damageUpgradeCount = checkpointDamageUpgradeCount;
	replenishCount = checkpointReplenishCount
	armorUpgradeCount = checkpointArmorUpgradeCount

	health = 100
	isAttacking = false
	baseRotation = 0
	isDead = false
	stopping = false
	inDrill = false
	bossAlive = false
	
func screen_shake(strength: float, duration: float):
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var camera = player.get_node_or_null("Camera2D")
	if not camera:
		return
	var tween = create_tween()
	tween.tween_method(func(t):
		camera.offset = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
	, 0.0, 1.0, duration)
	tween.tween_callback(func(): camera.offset = Vector2.ZERO)

# bossbar
signal boss_health_changed(value)

extends Node

# ========================== ENEMY SCENES ==========================
var Enemy1 = preload("res://scenes/Enemy1/Enemy1.tscn")
var Enemy2 = preload("res://scenes/Enemy2/Enemy2.tscn")
var Enemy3 = preload("res://scenes/Enemy3/Enemy3.tscn")

# ========================== LEVEL 1 CONFIG ==========================
var L1_W1_ENEMY = "Enemy1"
var L1_W1_START_INTERVAL: float = 3.0
var L1_W1_SPEED_DIVISOR: float = 8.0
var L1_W1_MIN_INTERVAL: float = 1.0
var L1_W1_COUNT: int = 10

var L1_W2_ENEMY = "Enemy2"
var L1_W2_START_INTERVAL: float = 3.0
var L1_W2_SPEED_DIVISOR: float = 9.0
var L1_W2_MIN_INTERVAL: float = 1.5
var L1_W2_COUNT: int = -1

# ========================== LEVEL 2 CONFIG ==========================
var L2_W1_ENEMY = "Enemy2"
var L2_W1_START_INTERVAL: float = 12.0
var L2_W1_SPEED_DIVISOR: float = 7.0
var L2_W1_MIN_INTERVAL: float = 1.0
var L2_W1_COUNT: int = 10

var L2_W2_ENEMY = "Enemy3"
var L2_W2_START_INTERVAL: float = 15.0
var L2_W2_SPEED_DIVISOR: float = 7.5
var L2_W2_MIN_INTERVAL: float = 1.5
var L2_W2_COUNT: int = -1

# ========================== SET THIS IN THE INSPECTOR ==========================
@export var my_level: int = 1

# ========================== INTERNAL STATE ==========================
var spawn_points: Array = []
var waves: Array = []
var current_wave_index: int = 0
var wave_spawn_count: int = 0
var current_interval: float = 0.0
var timer: float = 0.0
var started: bool = false
var wave2_started: bool = false

func _ready():
	for child in get_children():
		if child is Marker2D:
			spawn_points.append(child)

	if my_level == 1:
		waves = [
			{ "scene": L1_W1_ENEMY, "start_interval": L1_W1_START_INTERVAL, "divisor": L1_W1_SPEED_DIVISOR, "min_interval": L1_W1_MIN_INTERVAL, "count": L1_W1_COUNT },
			{ "scene": L1_W2_ENEMY, "start_interval": L1_W2_START_INTERVAL, "divisor": L1_W2_SPEED_DIVISOR, "min_interval": L1_W2_MIN_INTERVAL, "count": L1_W2_COUNT },
		]
	elif my_level == 2:
		waves = [
			{ "scene": L2_W1_ENEMY, "start_interval": L2_W1_START_INTERVAL, "divisor": L2_W1_SPEED_DIVISOR, "min_interval": L2_W1_MIN_INTERVAL, "count": L2_W1_COUNT },
			{ "scene": L2_W2_ENEMY, "start_interval": L2_W2_START_INTERVAL, "divisor": L2_W2_SPEED_DIVISOR, "min_interval": L2_W2_MIN_INTERVAL, "count": L2_W2_COUNT },
		]

func _process(delta):
	# Only run when the player is on this spawner's level
	if Globals.level != my_level:
		started = false
		return

	# First frame the player enters this level — start wave 1
	if not started:
		started = true
		wave2_started = false
		_start_wave(0)

	# Tick wave 1 (or whichever is current)
	timer += delta
	if timer >= current_interval:
		timer = 0.0
		_spawn_from_wave(current_wave_index)

func _start_wave(index: int):
	if index >= waves.size():
		return
	current_wave_index = index
	wave_spawn_count = 0
	current_interval = waves[index]["start_interval"]
	timer = 0.0

func _spawn_from_wave(index: int):
	var wave = waves[index]
	var scene = _get_scene(wave["scene"])
	if scene == null or spawn_points.is_empty():
		return

	var pos = spawn_points.pick_random().global_position
	var enemy = scene.instantiate()
	enemy.global_position = pos
	get_tree().current_scene.add_child(enemy)

	wave_spawn_count += 1

	# Accelerate spawn rate
	var reduction = current_interval / wave["divisor"]
	current_interval = max(current_interval - reduction, wave["min_interval"])

	# When wave 1 hits its count, start wave 2
	if not wave2_started and wave["count"] != -1 and wave_spawn_count >= wave["count"]:
		wave2_started = true
		_start_wave(current_wave_index + 1)

func _get_scene(enemy_name: String):
	match enemy_name:
		"Enemy1": return Enemy1
		"Enemy2": return Enemy2
		"Enemy3": return Enemy3
	return null

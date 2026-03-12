extends Node

# ========================== ENEMY SCENES ==========================
var Enemy1 = preload("res://scenes/Enemy1/Enemy1.tscn")
var Enemy2 = preload("res://scenes/Enemy2/Enemy2.tscn")
var Enemy3 = preload("res://scenes/Enemy3/Enemy3.tscn")

# ========================== LEVEL 1 CONFIG ==========================
var L1_INITIAL_SPAWNS: int = 2
var L1_W1_ENEMY = "Enemy1"
var L1_W1_START_INTERVAL: float = 4.5
var L1_W1_SPEED_DIVISOR: float = 7
var L1_W1_MIN_INTERVAL: float = 0.8
var L1_W1_COUNT: int = 5

var L1_W2_ENEMY = "Enemy2"
var L1_W2_START_INTERVAL: float = 4.0
var L1_W2_SPEED_DIVISOR: float = 8
var L1_W2_MIN_INTERVAL: float = 1.0
var L1_W2_COUNT: int = -1

# ========================== LEVEL 2 CONFIG ==========================
var L2_INITIAL_SPAWNS: int = 2
var L2_W1_ENEMY = "Enemy2"
var L2_W1_START_INTERVAL: float = 3.0
var L2_W1_SPEED_DIVISOR: float = 5.0
var L2_W1_MIN_INTERVAL: float = 0.8
var L2_W1_COUNT: int = 5

var L2_W2_ENEMY = "Enemy3"
var L2_W2_START_INTERVAL: float = 3.5
var L2_W2_SPEED_DIVISOR: float = 5.0
var L2_W2_MIN_INTERVAL: float = 1.0
var L2_W2_COUNT: int = -1

# ========================== LEVEL 3 CONFIG ==========================
var L3_INITIAL_SPAWNS: int = 2
var L3_W1_ENEMY = "Enemy3"
var L3_W1_START_INTERVAL: float = 2.5
var L3_W1_SPEED_DIVISOR: float = 4.0
var L3_W1_MIN_INTERVAL: float = 1.0
var L3_W1_COUNT: int = -1

# ========================== INTERNAL STATE ==========================
# { level_number: [Marker2D, ...] }
var level_spawn_points: Dictionary = {}
var level_waves: Dictionary = {}

@onready var bossSpawnPoint = $BossMarkers/BigDrilla/BossSpawnpoint
@export var drillaBoss: PackedScene
@export var mommaBatBoss: PackedScene

var current_wave_index: int = 0
var wave_spawn_count: int = 0
var current_interval: float = 0.0
var timer: float = 0.0
var started: bool = false
var wave2_started: bool = false
var last_level: int = -1

func _ready():
	add_to_group("enemies")
	# Collect spawn points from Level1, Level2, Level3 child nodes
	for child in get_children():
		if child.name.begins_with("Level"):
			var level_num = int(child.name.replace("Level", ""))
			var points: Array = []
			for marker in child.get_children():
				if marker is Marker2D:
					points.append(marker)
			level_spawn_points[level_num] = points

	# Define waves per level
	level_waves[1] = [
		{ "scene": L1_W1_ENEMY, "start_interval": L1_W1_START_INTERVAL, "divisor": L1_W1_SPEED_DIVISOR, "min_interval": L1_W1_MIN_INTERVAL, "count": L1_W1_COUNT },
		{ "scene": L1_W2_ENEMY, "start_interval": L1_W2_START_INTERVAL, "divisor": L1_W2_SPEED_DIVISOR, "min_interval": L1_W2_MIN_INTERVAL, "count": L1_W2_COUNT },
	]
	level_waves[2] = [
		{ "scene": L2_W1_ENEMY, "start_interval": L2_W1_START_INTERVAL, "divisor": L2_W1_SPEED_DIVISOR, "min_interval": L2_W1_MIN_INTERVAL, "count": L2_W1_COUNT },
		{ "scene": L2_W2_ENEMY, "start_interval": L2_W2_START_INTERVAL, "divisor": L2_W2_SPEED_DIVISOR, "min_interval": L2_W2_MIN_INTERVAL, "count": L2_W2_COUNT },
	]
	level_waves[3] = [
		{ "scene": L3_W1_ENEMY, "start_interval": L3_W1_START_INTERVAL, "divisor": L3_W1_SPEED_DIVISOR, "min_interval": L3_W1_MIN_INTERVAL, "count": L3_W1_COUNT },
	]
	level_waves[6] = [
		{ "scene": L3_W1_ENEMY, "start_interval": L3_W1_START_INTERVAL, "divisor": L3_W1_SPEED_DIVISOR, "min_interval": L3_W1_MIN_INTERVAL, "count": L3_W1_COUNT },
	]

func _process(delta):
	var level = Globals.level

	# No waves defined for this level
	if not level_waves.has(level):
		return

	# Level just changed — reset and spawn initial enemies
	if level != last_level:
		last_level = level
		started = true
		wave2_started = false
		_start_wave(0, level)
		_spawn_initial(level)
		
		if level == 3:
			var bossRef = drillaBoss.instantiate()
			bossRef.position = bossSpawnPoint.position
			add_child(bossRef)
		
		print(level)
		if level == 6:
			var bossRef = mommaBatBoss.instantiate()
			var markers = get_tree().get_nodes_in_group("mommaBatMarkers")
			var randomMarker = markers.pick_random()
			bossRef.position = randomMarker.position
			add_child(bossRef)

	timer += delta
	if timer >= current_interval:
		timer = 0.0
		_spawn_from_wave(current_wave_index, level)

func _spawn_initial(level: int):
	var initial_count = 0
	match level:
		1: initial_count = L1_INITIAL_SPAWNS
		2: initial_count = L2_INITIAL_SPAWNS
		3: initial_count = L3_INITIAL_SPAWNS

	var waves = level_waves[level]
	var scene = _get_scene(waves[0]["scene"])
	if scene == null:
		return

	for i in range(initial_count):
		_spawn_enemy_at_level(scene, level)

func _start_wave(index: int, level: int):
	var waves = level_waves[level]
	if index >= waves.size():
		return
	current_wave_index = index
	wave_spawn_count = 0
	current_interval = waves[index]["start_interval"]
	timer = 0.0

func _spawn_from_wave(index: int, level: int):
	var waves = level_waves[level]
	if index >= waves.size():
		return

	var wave = waves[index]
	var scene = _get_scene(wave["scene"])
	if scene == null:
		return

	_spawn_enemy_at_level(scene, level)
	wave_spawn_count += 1

	# Accelerate
	var reduction = current_interval / wave["divisor"]
	current_interval = max(current_interval - reduction, wave["min_interval"])

	# Trigger wave 2
	if not wave2_started and wave["count"] != -1 and wave_spawn_count >= wave["count"]:
		wave2_started = true
		_start_wave(current_wave_index + 1, level)
		
		

func _spawn_enemy_at_level(scene: PackedScene, level: int):
	var points = level_spawn_points.get(level, [])
	if points.is_empty():
		return
	var pos = points.pick_random().global_position
	var enemy = scene.instantiate()
	enemy.global_position = pos
	get_tree().current_scene.add_child(enemy)
	

func _get_scene(enemy_name: String):
	match enemy_name:
		"Enemy1": return Enemy1
		"Enemy2": return Enemy2
		"Enemy3": return Enemy3
	return null

extends Node

@export var genericSlime: PackedScene
@export var tankySlime: PackedScene
@export var shooterSlime: PackedScene

@export var genericBat: PackedScene
@export var flameBat: PackedScene
@export var poisonBat: PackedScene

@export var drillaBoss: PackedScene
@export var mommaBatBoss: PackedScene



class WaveData:
	var totalEnemies: int
	var spawnInterval: float
	var minInterval: float # floor — won't go faster than this
	var scalingRate: float # seconds shaved off interval per 10s in level
	var batchSize: int # enemies before a rest
	var restDuration: float # seconds of rest between batches
	var enemyWeights: Dictionary

	func _init(total: int, interval: float, min_interval: float, scaling: float, batch: int, rest: float, weights: Dictionary) -> void:
		totalEnemies = total
		spawnInterval = interval
		minInterval   = min_interval
		scalingRate   = scaling
		batchSize     = batch
		restDuration  = rest
		enemyWeights = weights

	func pickEnemyKey() -> String:
		var total_weight := 0
		for w in enemyWeights.values():
			total_weight += w
		var roll := randi() % total_weight
		var cumulative := 0
		for key in enemyWeights:
			cumulative += enemyWeights[key]
			if roll < cumulative:
				return key
		return enemyWeights.keys()[0]
		
# total, startInterval, minInterval, scalingRate, batchSize, restDuration, weights
var waveTable: Dictionary = {
	1: WaveData.new(8,  2.5, 1.6, 0.08, 4, 2.0, { "genericSlime": 7, "tankySlime": 3 }),
	2: WaveData.new(12, 2.2, 1.4, 0.10, 4, 2.0, { "genericSlime": 5, "tankySlime": 3, "shooterSlime": 2 }),
	3: WaveData.new(10, 2.0, 1.3, 0.10, 3, 1.0, { }),
	4: WaveData.new(16, 1.8, 1.1, 0.12, 5, 2.0, { }),
	5: WaveData.new(16, 1.8, 1.0, 0.12, 5, 1.5, { "genericBat": 4, "flameBat": 3, "shooterSlime": 3, "tankySlime": 2 }),
	6: WaveData.new(20, 1.6, 0.9, 0.14, 6, 1.5, { "genericBat": 3, "flameBat": 3, "poisonBat": 3, "shooterSlime": 4, "tankySlime": 2 }),
	7: WaveData.new(14, 1.5, 0.8, 0.15, 4, 1.0, { }),
}

enum SpawnState { SPAWNING, RESTING }

const MIN_SPAWN_DIST: float = 200.0

var levelSpawnPoints: Dictionary = {}
var currentInterval: float = 0.0
var spawnTimer: float = 0.0
var restTimer: float = 0.0
var spawnState: SpawnState = SpawnState.SPAWNING
var timeInLevel: float = 0.0
var started: bool = false
var lastLevel: int = -1
var enemiesSpawned: int = 0
var enemiesInBatch: int = 0


func _ready() -> void:
	
	for child in get_children():
		if child.name.begins_with("Level"):
			var level_num = int(child.name.replace("Level", ""))
			var points: Array = []
			for marker in child.get_children():
				if marker is Marker2D:
					points.append(marker)
			levelSpawnPoints[level_num] = points
			
	
func _process(delta: float) -> void:

	var level = Globals.level
	
	if level != lastLevel:
		
		lastLevel = level
		
		if level == 3:
			var bossRef = drillaBoss.instantiate()
			#bossRef.position = bossSpawnPoint.position
			add_child(bossRef)
			return
			
		elif level == 7:
			var bossRef = mommaBatBoss.instantiate()
			var markers = get_tree().get_nodes_in_group("mommaBatMarkers")
			var randomMarker = markers.pick_random()
			bossRef.position = randomMarker.position
			add_child(bossRef)
			return
		
		if not levelSpawnPoints.has(level) or levelSpawnPoints[level].is_empty():
			return
		
		enemiesSpawned = 0
		enemiesInBatch = 0
		spawnTimer = 0.0
		restTimer = 0.0
		timeInLevel = 0.0
		spawnState = SpawnState.SPAWNING
		started = true
		if waveTable.has(level):
			currentInterval = waveTable[level].spawnInterval
	
	if not started:
		return
		
	timeInLevel += delta
	updateDifficulty(level)
	
	match spawnState:
		SpawnState.RESTING:
			restTimer += delta
			if restTimer >= waveTable[level].restDuration:
				restTimer = 0.0
				enemiesInBatch = 0
				spawnState = SpawnState.SPAWNING

		SpawnState.SPAWNING:
			spawnTimer += delta
			if spawnTimer >= currentInterval:
				spawnTimer = 0.0
				startWave(level)

func updateDifficulty(level: int) -> void:
	if not waveTable.has(level):
		return
	var wave: WaveData = waveTable[level]
	
	# Every 10 seconds in the level, reduce interval by scalingRate (floored at minInterval)
	var reduction := (timeInLevel / 10.0) * wave.scalingRate
	currentInterval = max(wave.minInterval, wave.spawnInterval - reduction)
	
func startWave(level: int) -> void:
	if not waveTable.has(level):
		return
	var wave: WaveData = waveTable[level]
	if enemiesSpawned >= wave.totalEnemies:
		return
	if wave.enemyWeights.is_empty():
		return
		
	var points: Array = levelSpawnPoints[level]
	if points.is_empty():
		return
	
	var validPoints := getValidSpawnPoints(points)
	if validPoints.is_empty():
		validPoints = points 

	var pos: Vector2 = validPoints.pick_random().global_position
	var scene := getSceneForKey(wave.pickEnemyKey())
	if scene == null:
		return

	var enemy := scene.instantiate()
	enemy.global_position = pos
	get_tree().current_scene.add_child(enemy)
	enemiesSpawned += 1
	enemiesInBatch += 1
	
	if enemiesInBatch >= wave.batchSize:
		spawnState = SpawnState.RESTING


func getSceneForKey(key: String) -> PackedScene:
	match key:
		"genericSlime": return genericSlime
		"tankySlime": return tankySlime
		"shooterSlime": return shooterSlime
		"genericBat": return genericBat
		"flameBat": return flameBat
		"poisonBat": return poisonBat
	return null
	
func getValidSpawnPoints(points: Array) -> Array:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return points
	return points.filter(func(p): return p.global_position.distance_to(player.global_position) >= MIN_SPAWN_DIST)
	

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
	var enemyWeights: Dictionary

	func _init(total: int, interval: float, weights: Dictionary) -> void:
		totalEnemies = total
		spawnInterval = interval
		enemyWeights = weights

	func pick_enemy_key() -> String:
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

var waveTable: Dictionary = {
	1: WaveData.new(8,  2.5, { "genericSlime": 7, "tankySlime": 3 }),
	2: WaveData.new(12, 2.2, { "genericSlime": 5, "tankySlime": 3, "genericBat": 2 }),
	3: WaveData.new(10, 2.0, { }),
	4: WaveData.new(16, 1.8, { }),
	5: WaveData.new(16, 1.8, { "genericBat": 4, "flameBat": 3, "shooterSlime": 3, "tankySlime": 2 }),
	6: WaveData.new(20, 1.6, { "genericBat": 3, "flameBat": 3, "poisonBat": 3, "shooterSlime": 4, "tankySlime": 2 }),
	7: WaveData.new(14, 1.5, { }),
}

var levelSpawnPoints: Dictionary = {}


var current_interval: float = 0.0
var timer: float = 0.0
var started: bool = false
var lastLevel: int = -1



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
		
		checkForSpawnBoss(level)
		
		if not levelSpawnPoints[level]:
			return
			
		lastLevel = level
		started = true
	

	timer += delta
	if timer >= current_interval:
		timer = 0.0
		startWave(level)

func startWave(level: int):
	var points = levelSpawnPoints[level]
	if points.is_empty():
		return
	var pos = points.pick_random().global_position
	
	#var enemy = scene.instantiate()
	#enemy.global_position = pos
	#get_tree().current_scene.add_child(enemy)


func checkForSpawnBoss(level: int):
	
	if level == 3:
		var bossRef = drillaBoss.instantiate()
		#bossRef.position = bossSpawnPoint.position
		add_child(bossRef)
		
	if level == 6:
		var bossRef = mommaBatBoss.instantiate()
		var markers = get_tree().get_nodes_in_group("mommaBatMarkers")
		var randomMarker = markers.pick_random()
		bossRef.position = randomMarker.position
		add_child(bossRef)

extends Node

@export var genericSlime: PackedScene
@export var tankySlime: PackedScene
@export var shooterSlime: PackedScene

@export var genericBat: PackedScene
@export var flameBat: PackedScene
@export var poisonBat: PackedScene

@export var drillaBoss: PackedScene
@export var mommaBatBoss: PackedScene

var levelSpawnPoints: Dictionary = {}

var current_interval: float = 0.0
var timer: float = 0.0
var started: bool = false
var lastLevel: int = -1


func _ready() -> void:
	
	pass
	
func _process(delta: float) -> void:

	var level = Globals.level
	

	if level != lastLevel:
		
		if not levelSpawnPoints[level]:
			return
			
		lastLevel = level
		started = true
	

	timer += delta
	if timer >= current_interval:
		timer = 0.0
		#_spawn_from_wave(current_wave_index, level)
		
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

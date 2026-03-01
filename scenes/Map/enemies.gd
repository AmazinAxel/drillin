extends Node

var enemy_scene = preload("res://scenes/Enemy1/Enemy1.tscn")
var spawn_interval: float = 3.0
var max_enemies: int = 10

var spawn_points = []
var timer = 0.0

func _ready():
	for child in get_children():
		if child is Marker2D:
			spawn_points.append(child)
	
	for point in spawn_points:
		call_deferred("spawn_enemy", point.global_position)

func _process(_delta):
	timer += _delta
	if timer >= spawn_interval:
		timer = 0.0
		spawn_enemy(spawn_points.pick_random().global_position)

func spawn_enemy(pos: Vector2):
	var enemy = enemy_scene.instantiate()
	enemy.global_position = pos
	get_tree().current_scene.add_child(enemy)

extends Node

@export var boss: PackedScene

#func _ready(): # testing only
	#var bossRef = boss.instantiate()
	#bossRef.position = get_tree().get_first_node_in_group("bossSpawnpoint").position
	#add_child(bossRef)
	
@onready var poison_overlay = $PoisonCanvas/PoisonRect

func _ready():
	PoisonManager.poison_applied.connect(_on_poison_applied)

func _on_poison_applied(stacks: int):
	print("applied")
	var target_intensity = (float(stacks) / float(PoisonManager.max_stacks)) * 1.0
	
	if _poison_tween:
		_poison_tween.kill()
	
	poison_overlay.material.set_shader_parameter("intensity", target_intensity)
	_poison_tween = create_tween()
	_poison_tween.tween_method(
		func(v): poison_overlay.material.set_shader_parameter("intensity", v),
		target_intensity, 0.0, 4.0 + stacks * 1.5 
	)

var _poison_tween: Tween

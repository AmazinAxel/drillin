extends AnimatedSprite2D

@onready var area = $Area2D
@onready var gui = $Label
@onready var player = get_parent().get_node("Player")
@onready var drillShop = get_parent().get_node("DrillaShop")

func _ready() -> void:
	print(gui)
	print(area)
	print(player)
	print(drillShop)
	
var trigger_distance := 50.0  # pixels

func _process(delta: float) -> void:
	if not player:
		return

	var dist = global_position.distance_to(player.global_position)
	
	if dist < trigger_distance:
		gui.visible = true
	else:
		gui.visible = false

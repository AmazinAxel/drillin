extends AnimatedSprite2D

@onready var area = $Area2D
@onready var gui = $Control
@onready var player = get_parent().get_node("Player")

func _ready() -> void:
	print(gui)
	print(area)
	print(player)
	
var trigger_distance := 50.0  # pixels

func _process(delta: float) -> void:
	if not player:
		return

	var dist = global_position.distance_to(player.global_position)

	gui.visible = dist < trigger_distance

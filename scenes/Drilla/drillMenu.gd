extends AnimatedSprite2D

@onready var area = $Area2D
@onready var gui = $Label
@onready var player = get_parent().get_node("Player")

func _ready() -> void:
	print(gui)
	print(area)
	print(player)
	play("default")
	
var trigger_distance := 50.0  # pixels

func _process(delta: float) -> void:
	if not player:
		return
	var dist = global_position.distance_to(player.global_position)
	
	if dist < trigger_distance:
		gui.visible = true
		if Input.is_action_just_pressed("interact"):
			get_tree().change_scene_to_file("res://scenes/UI/DrillaShop.tscn");
	else:
		gui.visible = false
	
	# Keep label from flipping with parent
	gui.scale.x = abs(gui.scale.x) * sign(scale.x)

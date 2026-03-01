extends AnimatedSprite2D

@onready var area = $Area2D
@onready var gui = $Control

func _ready() -> void:
	pass # Replace with function body.

func _on_Area2D_body_entered(body):
	print(body);
	if body.name == "Player":
		gui.visible = true;

func _on_Area2D_body_exited(body):
	if body.name == "Player":
		gui.visible = false
		
func _process(delta: float) -> void:
	pass

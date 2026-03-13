extends Node2D

@export var parallax_strength: float = 10.0  # how many pixels max offset
@export var smoothing: float = 15.0           # how smoothly it follows

var target_offset := Vector2.ZERO

func _process(delta: float) -> void:
	var viewport_size = get_viewport_rect().size
	var mouse_pos = get_viewport().get_mouse_position()
	
	var normalized = (mouse_pos - viewport_size / 2.0) / (viewport_size / 2.0)
	target_offset = -normalized * parallax_strength
	position = position.lerp(target_offset, delta * smoothing)

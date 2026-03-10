extends Node2D

var time_elapsed: float = 0.0
var lifetime: float = 3.0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	time_elapsed += delta
	
	var t = time_elapsed / lifetime
	var flicker_speed = lerp(10.0, 40.0, t)
	var flicker = (sin(time_elapsed * flicker_speed) + sin(time_elapsed * flicker_speed * 1.7)) / 2.0
	flicker = (flicker + 1.0) / 2.0 
	
	var base_alpha = 1.0 - t
	$Sprite2D.modulate.a = base_alpha * flicker
	$PointLight2D.energy = (base_alpha - 0.5) * flicker
	print((base_alpha) * flicker)
	
	if time_elapsed >= lifetime:
		queue_free()

extends Node2D

var time_elapsed: float = 0.0
var light_duration: float = 0.6
var damage_dealt: bool = false

func _process(delta: float) -> void:
	time_elapsed += delta
	var t = time_elapsed / light_duration

	if t < 0.2:
		$PointLight2D.energy = lerp(0.0, 0.5, t / 0.2)
	elif t < 1.0:
		$PointLight2D.energy = lerp(0.5, 0.0, (t - 0.2) / 0.8)
	else:
		$PointLight2D.energy = 0.0

func _on_animated_sprite_2d_animation_finished() -> void:
	queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	
	if body.name != "Player":
		return
		
	var p = get_tree().get_first_node_in_group("player")
	if p:
		p.take_damage(10)

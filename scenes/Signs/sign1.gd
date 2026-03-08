extends Node2D

var tween: Tween


func _on_area_2d_body_entered(body: Node2D) -> void:
	
	if body.name != "Player":
		return
	$Control/Label.visible = true
	$Control/Label.add_theme_color_override("font_color", Color(1, 1, 1, 0))
	
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_method(set_label_alpha, 0.0, 1.0, 0.5)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name != "Player":
		return
		
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_method(set_label_alpha, 1.0, 0.0, 0.5)
	await tween.finished
	$Control/Label.visible = false
	
func set_label_alpha(alpha: float) -> void:
	var current_color = $Control/Label.get_theme_color("font_color") if $Control/Label.has_theme_color_override("font_color") else Color.WHITE
	$Control/Label.add_theme_color_override("font_color", Color(current_color.r, current_color.g, current_color.b, alpha))

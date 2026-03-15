extends Button

func _on_button_up() -> void:
	var drill = get_tree().get_first_node_in_group("drill")
	if drill:
		$"../UIButtonClicked".play()
		drill.stop_drill()


func _on_mouse_entered() -> void:
	$"../UIHoverSound".play()

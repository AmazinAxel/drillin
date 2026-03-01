extends Button

func _on_button_up() -> void:
	var drill = get_tree().get_first_node_in_group("drill")
	if drill:
		drill.stop_drill()

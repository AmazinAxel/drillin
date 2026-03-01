extends Button

func _on_pressed() -> void:
	disabled = true
	
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.size = get_viewport().get_visible_rect().size
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.add_child(overlay)
	get_tree().root.add_child(canvas)
	
	# Fade to black
	var tween = get_tree().create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.5)
	tween.tween_callback(func():
		# Now fully black — change scene
		get_tree().change_scene_to_file("res://scenes/Main/Main.tscn")
		
		# Fade from black — create tween bound to overlay (still in tree)
		var tween2 = overlay.create_tween()
		tween2.tween_interval(0.1)  # tiny delay for scene to load
		tween2.tween_property(overlay, "color:a", 0.0, 0.5)
		tween2.tween_callback(canvas.queue_free)
	)

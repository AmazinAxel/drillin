extends Button

func _on_pressed() -> void:
	disabled = true
	$UIButtonClicked.play()
	
	var drill = get_tree().get_first_node_in_group("backgroundDrill")
	if drill:
		await drill.backgroundExitAnimation()
	
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.size = get_viewport().get_visible_rect().size
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Spinning icon
	var spinner = TextureRect.new()
	spinner.texture = preload("res://scenes/Drilla/MyDrilla.png")
	spinner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spinner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var spinner_size = Vector2(55, 55)
	spinner.custom_minimum_size = spinner_size
	spinner.size = spinner_size
	spinner.position = overlay.size - spinner_size - Vector2(50, 50)
	spinner.pivot_offset = spinner_size / 2.0
	spinner.modulate.a = 0.0

	# dis so broken but IT WORK
	var shader = Shader.new()
	shader.code = "
	shader_type canvas_item;
	void fragment() {
		vec4 tex = texture(TEXTURE, UV);
		COLOR = vec4(COLOR.rgb, tex.a * 0.7 * COLOR.a);
	}
	"
	
	var mat = ShaderMaterial.new()
	mat.shader = shader
	spinner.material = mat

	overlay.add_child(spinner)

	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.add_child(overlay)
	get_tree().root.add_child(canvas)

	# Fade to black
	var tween = get_tree().create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.5)
	tween.tween_callback(func():
		spinner.modulate.a = 1.0

		var spin_tween = canvas.create_tween()
		spin_tween.set_loops()
		spin_tween.tween_property(spinner, "rotation", TAU, 2.5).from(0.0)

		ResourceLoader.load_threaded_request("res://scenes/Main/Main.tscn")

		# async load
		var timer = Timer.new()
		canvas.add_child(timer)
		timer.wait_time = 0.05
		timer.timeout.connect(func():
			var status = ResourceLoader.load_threaded_get_status("res://scenes/Main/Main.tscn")
			if status == ResourceLoader.THREAD_LOAD_LOADED:
				timer.stop()
				var scene = ResourceLoader.load_threaded_get("res://scenes/Main/Main.tscn")
				get_tree().change_scene_to_packed(scene)

				# Use dict so lambda captures by reference
				var state = { "elapsed": 0.0 }
				var fade_time = 0.5
				var dt = 1.0 / 60.0

				var fade_timer = Timer.new()
				canvas.add_child(fade_timer)
				fade_timer.wait_time = dt
				fade_timer.timeout.connect(func():
					state.elapsed += dt
					var t = clampf(state.elapsed / fade_time, 0.0, 1.0)
					overlay.color.a = 1.0 - t
					spinner.modulate.a = 1.0 - t
					spinner.rotation += TAU * dt / 2.5

					if t >= 1.0:
						fade_timer.stop()
						spin_tween.kill()
						canvas.queue_free()
				)
				fade_timer.start()
				Globals.started = true;
		)
		timer.start()
	)

func _on_mouse_entered() -> void:
	$UIHoverSound.play()

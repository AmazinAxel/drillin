extends TextureProgressBar

func _ready():
	max_value = Globals.bossbarMaxValue
	value = Globals.bossbarMaxValue # starts maxed
	Globals.boss_health_changed.connect(_on_boss_health_changed)
	print(max_value)

func _on_boss_health_changed(newHealth):
	print("max health: ", Globals.bossbarMaxValue, " health: ", newHealth)
	value = newHealth

	# flash healthbar
	modulate = Color(3, 0.3, 0.3)  # red flash
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.3)
	tween.tween_property($bossName, "modulate", Color(1, 1, 1), 0.3)

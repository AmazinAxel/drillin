extends TextureProgressBar

func _ready():
	max_value = Globals.bossbarMaxValue
	value = Globals.bossbarMaxValue
	Globals.boss_health_changed.connect(_on_boss_health_changed)


func _on_boss_health_changed(newHealth):
	value = newHealth
	modulate = Color(3, 0.3, 0.3)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.3)

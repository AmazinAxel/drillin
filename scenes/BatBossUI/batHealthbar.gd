extends TextureProgressBar

func _ready():
	max_value = 110
	min_value = -10
	value = 80
	Globals.boss_health_changed.connect(_on_boss_health_changed)

func _on_boss_health_changed(newHealth):
	value = remap(newHealth, 0, Globals.bossbarMaxValue, 10, 90)
	modulate = Color(3, 0.3, 0.3)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.3)

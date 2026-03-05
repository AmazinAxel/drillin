extends TextureProgressBar

func _ready():
	max_value = Globals.bossbar
	value = Globals.bossbar
	Globals.boss_health_changed.connect(_on_boss_health_changed)

func _on_boss_health_changed(value):
	value = value

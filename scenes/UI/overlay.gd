extends CanvasLayer

var is_showing := false
var tween: Tween

@onready var control = $Control

func _ready() -> void:
	control.get_node("lives").text = str(Globals.lives)
	control.get_node("minerals").text = str(Globals.minerals)

func _process(_delta) -> void:
	var should_show = !Globals.inDrill and Globals.started
	if should_show and not is_showing:
		fade_in()
	elif not should_show and is_showing:
		fade_out()

func fade_in() -> void:
	is_showing = true
	if tween:
		tween.kill()
	visible = true
	tween = create_tween()
	tween.tween_property(control, "modulate:a", 1.0, 0.3)

func fade_out() -> void:
	is_showing = false
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(control, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): visible = false)

func setMinerals(minerals):
	control.get_node("minerals").text = str(minerals)

func setLives(lives):
	control.get_node("lives").text = str(lives)

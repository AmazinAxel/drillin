extends CanvasLayer

func _ready() -> void:
	visible = Globals.started
	print("Globals.started = ", Globals.started)
	$lives.text = str(Globals.lives);
	$minerals.text = str(Globals.minerals);

func setMinerals(minerals):
	$minerals.text = str(minerals);

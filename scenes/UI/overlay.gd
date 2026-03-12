extends CanvasLayer

func _ready() -> void:
	$lives.text = str(Globals.lives);
	$minerals.text = str(Globals.minerals);

func setMinerals(minerals):
	$minerals.text = str(minerals);

extends Node

# checkpoint system

func _ready():
	if Globals.checkpoint == 1:
		$Player.position = $Map/Checkpoints/PlayerStage1.position
		$Drilla.position = $Map/Checkpoints/DrillaStage1.position
	elif Globals.checkpoint == 2:
		$Player.position = $Map/Checkpoints/PlayerStage2.position
		$Drilla.position = $Map/Checkpoints/DrillaStage2.position
	mainHUD.setLives(Globals.lives);
	mainHUD.setMinerals(Globals.minerals);

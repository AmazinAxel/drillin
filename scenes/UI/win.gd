extends Control

func _ready() -> void:
	var endTime = Time.get_ticks_msec()

	# BIG DRILLA BOSS
	var boss1Ms = endTime - Globals.boss1Time;
	var boss1Time = boss1Ms / 1000.0;
	var boss1Minutes := int(boss1Time) / 60;
	var boss1Seconds := int(boss1Time) % 60;
	$HBoxContainer/Control2/Label4.text = "Time to Big Drilla: %02d:%02d" % [boss1Minutes, boss1Seconds];

	# MOMMA BAT BOSS
	var boss2Ms = endTime - Globals.boss2Time;
	var boss2Time = boss2Ms / 1000.0;
	var boss2Minutes := int(boss2Time) / 60;
	var boss2Seconds := int(boss2Time) % 60;
	$HBoxContainer/Control2/Label3.text = "Time to Momma Bat: %02d:%02d" % [boss1Minutes, boss1Seconds];

	# CRYSTAL BOSS
	var boss3Ms = endTime - Globals.boss3Time;
	var boss3Time = boss2Ms / 1000.0;
	var boss3Minutes := int(boss3Time) / 60;
	var boss3Seconds := int(boss3Time) % 60;
	$HBoxContainer/Control2/Label5.text = "Time to Crystal Boss: %02d:%02d" % [boss1Minutes, boss1Seconds];

	

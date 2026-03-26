extends Control

func _ready() -> void:

	# BIG DRILLA BOSS
	var boss1Ms = Globals.boss1Time - Globals.startTime;
	var boss1Time = boss1Ms / 1000.0;
	var boss1Minutes = int(boss1Time) / 60;
	$VBoxContainer/Control2/bigdrilla.text = str(boss1Minutes) + "m";

	# MOMMA BAT BOSS
	var boss2Ms = Globals.boss2Time - Globals.startTime;
	var boss2Time = boss2Ms / 1000.0;
	var boss2Minutes = int(boss2Time) / 60;
	$VBoxContainer/Control2/mombat.text = str(boss2Minutes) + "m";

	# OVERALL - this includes the third level boss as well!!!
	var overall = Time.get_ticks_msec();
	var overallMs = overall - Globals.startTime;
	var overallTime = overallMs / 1000.0;
	var overallMinutes = int(overallTime) / 60;
	$VBoxContainer/Control2/overall.text = str(overallMinutes) + "m";
	

extends Control

func _ready() -> void:

	# BIG DRILLA BOSS
	# TEMP REMOVE ME
	#Globals.boss1Time = Time.get_ticks_msec();
	print(Globals.startTime, Globals.boss1Time, Globals.boss2Time, Time.get_ticks_msec())
	var boss1Ms = Globals.boss1Time - Globals.startTime;
	var boss1Time = boss1Ms / 1000.0;
	var boss1Minutes = int(boss1Time) / 60;
	$VBoxContainer/Control2/bigdrilla.text = str(boss1Minutes) + "m";

	# MOMMA BAT BOSS
	var boss2Ms = Globals.boss2Time - Globals.startTime;
	var boss2Time = boss2Ms / 1000.0;
	var boss2Minutes = int(boss2Time) / 60;
	$VBoxContainer/Control2/mombat.text = str(boss1Minutes) + "m";

	# OVERALL
	var overall = Time.get_ticks_msec();
	var overallMs = overall - Globals.startTime;
	var overallTime = overallMs / 1000.0;
	var overallMinutes = int(overallTime) / 60;
	$VBoxContainer/Control2/overall.text = str(overallMinutes) + "m";

	# CRYSTAL BOSS
	#var boss3Ms = endTime - Globals.boss3Time;
	#var boss3Time = boss2Ms / 1000.0;
	#var boss3Minutes := int(boss3Time) / 60;
	#var boss3Seconds := int(boss3Time) % 60;
	#$HBoxContainer/Control2/Label5.text = "Time to Crystal Boss: %02d:%02d" % [boss1Minutes, boss1Seconds];

	

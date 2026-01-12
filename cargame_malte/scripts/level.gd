extends Node3D

func _ready():
	var manager = get_node("/root/ScoreAndTimeManager")
	manager.start_timer()

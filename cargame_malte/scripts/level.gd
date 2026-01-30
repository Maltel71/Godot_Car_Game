extends Node3D

@export var level_start_time: float = 60.0  # Adjustable in inspector

func _ready():
	var manager = get_node("/root/ScoreAndTimeManager")
	manager.start_timer(level_start_time)

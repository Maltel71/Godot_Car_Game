extends Node

var level_time: float = 0.0
var level_score: int = 0
var is_timing: bool = false

func _ready():
	start_timer()

func _process(delta):
	if is_timing:
		level_time += delta

func start_timer():
	level_time = 0.0
	level_score = 0
	is_timing = true

func stop_timer():
	is_timing = false

func add_score(points: int):
	level_score += points

func get_time() -> float:
	return level_time

func get_score() -> int:
	return level_score

extends CanvasLayer

@onready var timer_label = $Panel/HBoxContainer/TimerLabel
@onready var score_label = $Panel/HBoxContainer/ScoreLabel
var manager

func _ready():
	manager = get_node("/root/ScoreAndTimeManager")

func _process(_delta):
	if not manager:
		return
		
	var time = manager.get_time()
	var minutes = int(time / 60)
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 100)
	timer_label.text = "Timer: %02d:%02d:%02d" % [minutes, seconds, milliseconds]
	
	score_label.text = "Score: %d" % manager.get_score()

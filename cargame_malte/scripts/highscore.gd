extends CanvasLayer

@onready var score_label = $Panel/HBoxContainer/ScoreLabel
@onready var delivery_label = $Panel/HBoxContainer/DeliveryLabel
@onready var timer_label = $Panel/HBoxContainer/TimerLabel
@onready var status_label = $Panel/HBoxContainer/DeliveryStatus
var manager

func _ready():
	manager = get_node("/root/ScoreAndTimeManager")

func _process(_delta):
	if not manager:
		return
	score_label.text = "Score: %d" % manager.get_score()
	delivery_label.text = "Deliver to: %s" % manager.get_target_delivery()
	if manager.is_delivering:
		timer_label.text = "%ds" % int(manager.delivery_timer)
		status_label.text = _get_delivery_status()
	else:
		timer_label.text = ""
		status_label.text = ""

func _get_delivery_status() -> String:
	var t = manager.delivery_timer
	var base = manager.base_delivery_time
	if t <= base * manager.very_good_multiplier:
		return "Very Good time"
	elif t <= base * manager.good_multiplier:
		return "Good time"
	elif t <= base * manager.bad_multiplier:
		return "Bad time"
	else:
		return "Very Bad time!"

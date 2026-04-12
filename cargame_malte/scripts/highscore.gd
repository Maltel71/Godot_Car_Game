extends CanvasLayer

@onready var score_label   = $Panel/HBoxContainer/ScoreLabel
@onready var delivery_label = $Panel/HBoxContainer/DeliveryLabel
@onready var timer_label   = $Panel/HBoxContainer/TimerLabel
@onready var status_label  = $Panel/HBoxContainer/DeliveryStatus

@export var delivery_arrow: TextureRect

var manager

func _ready():
	manager = get_node("/root/ScoreAndTimeManager")
	if delivery_arrow:
		delivery_arrow.hide()

func _process(_delta):
	if not manager:
		return

	score_label.text    = "Score: %d" % manager.get_score()
	delivery_label.text = "Deliver to: %s" % manager.get_target_delivery()

	if manager.is_delivering:
		timer_label.text  = "%ds" % int(manager.delivery_timer)
		status_label.text = _get_delivery_status()
	else:
		timer_label.text  = ""
		status_label.text = ""

	_update_arrow()

func _update_arrow():
	if not delivery_arrow:
		return

	var target: Node3D = manager.target_delivery_node
	if not manager.is_delivering or not is_instance_valid(target):
		delivery_arrow.hide()
		return

	var cam = get_viewport().get_camera_3d()
	if not cam:
		return

	var viewport_size  = get_viewport().get_visible_rect().size
	var center         = viewport_size / 2.0
	var to_target      = target.global_position - cam.global_position
	var is_behind      = cam.global_transform.basis.z.dot(to_target) > 0.0

	var screen_pos = cam.unproject_position(target.global_position)

	# When behind camera, flip the point through center so arrow points backward
	if is_behind:
		screen_pos = center + (center - screen_pos)

	var dir = (screen_pos - center).normalized()

	# Check if on screen (with margin)
	var margin  = 80.0
	var on_screen = (
		screen_pos.x > margin and screen_pos.x < viewport_size.x - margin and
		screen_pos.y > margin and screen_pos.y < viewport_size.y - margin and
		not is_behind
	)

	if on_screen:
		delivery_arrow.hide()
	else:
		delivery_arrow.show()
		delivery_arrow.position = center + dir * (min(center.x, center.y) - margin)
		delivery_arrow.rotation = dir.angle()

func _get_delivery_status() -> String:
	var t    = manager.delivery_timer
	var base = manager.base_delivery_time
	if t <= base * manager.very_good_multiplier:
		return "Very Good time"
	elif t <= base * manager.good_multiplier:
		return "Good time"
	elif t <= base * manager.bad_multiplier:
		return "Bad time"
	else:
		return "Very Bad time!"

extends CanvasLayer

@onready var score_label    = $Panel/HBoxContainer/ScoreLabel
@onready var delivery_label = $Panel/HBoxContainer/DeliveryLabel
@onready var timer_label    = $Panel/HBoxContainer/TimerLabel
@onready var status_label   = $Panel/HBoxContainer/DeliveryStatus
@onready var speed_label    = $Panel2/HBoxContainer_Speed/CurrentSpeedLabel
@onready var star_xp_label  = $Panel/HBoxContainer/StarXPMeter
@onready var stars = [
	$HBoxContainer_StarRating/Star1,
	$HBoxContainer_StarRating/Star2,
	$HBoxContainer_StarRating/Star3,
	$HBoxContainer_StarRating/Star4,
	$HBoxContainer_StarRating/Star5,
]

@export var delivery_arrow: TextureRect

var manager
var car: VehicleBody3D
var _arrow_visible: bool = false
var _smoothed_screen_pos: Vector2 = Vector2.ZERO

func _ready():
	manager = get_node("/root/ScoreAndTimeManager")
	car = get_tree().get_first_node_in_group("car")
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

	if car:
		speed_label.text = "%03d mph" % int(car.linear_velocity.length() * 2.237)

	var rating = manager.get_star_rating()
	for i in stars.size():
		stars[i].modulate.a = 1.0 if i < rating else 0.3

	star_xp_label.text = "starxpmeter: %s" % manager.get_star_xp_progress()

	_update_arrow()

func _update_arrow():
	if not delivery_arrow:
		return

	var target: Node3D = manager.target_delivery_node
	if not manager.is_delivering or not is_instance_valid(target):
		delivery_arrow.hide()
		_arrow_visible = false
		return

	var cam = get_viewport().get_camera_3d()
	if not cam:
		return

	var viewport_size = get_viewport().get_visible_rect().size
	var center        = viewport_size / 2.0
	var to_target     = target.global_position - cam.global_position
	var is_behind     = cam.global_transform.basis.z.dot(to_target) > 0.05

	var raw_pos = cam.unproject_position(target.global_position)
	_smoothed_screen_pos = lerp(_smoothed_screen_pos, raw_pos, 0.15)
	var screen_pos = _smoothed_screen_pos

	if is_behind:
		screen_pos = center + (center - screen_pos)

	var dir = (screen_pos - center).normalized()

	var margin = 120.0 if _arrow_visible else 60.0
	var on_screen = (
		screen_pos.x > margin and screen_pos.x < viewport_size.x - margin and
		screen_pos.y > margin and screen_pos.y < viewport_size.y - margin and
		not is_behind
	)

	_arrow_visible = not on_screen

	if on_screen:
		delivery_arrow.hide()
	else:
		delivery_arrow.show()
		var target_pos = center + dir * (min(center.x, center.y) - 60.0)
		delivery_arrow.position = lerp(delivery_arrow.position, target_pos, 0.2)
		delivery_arrow.rotation = lerp_angle(delivery_arrow.rotation, dir.angle(), 0.2)

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

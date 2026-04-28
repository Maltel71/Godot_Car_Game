extends CanvasLayer

@onready var money_label    = $Control_Stats/MoneyLabel
@onready var delivery_label = $Panel_Delivery/HBoxContainer/DeliveryLabel
@onready var timer_label    = $Panel_Delivery/HBoxContainer/TimerLabel
@onready var status_label   = $Panel_Delivery/HBoxContainer/DeliveryStatus
@onready var speed_label    = $Panel_Car/CurrentSpeedLabel
@onready var star_xp_label  = $Control_Debug/StarXPMeter
@onready var radio_label    = $Control_Debug/RadioLabel
@onready var phase_label    = $Control_Debug/PhaseLabel
@onready var panel_delivery = $Panel_Delivery
@onready var height_label   = $Panel_Car/CurrentHeightLabel
@export var height_world_zero: float = 0.0
@onready var stars = [
	$Control_Stats/HBoxContainer_StarRating/Star1,
	$Control_Stats/HBoxContainer_StarRating/Star2,
	$Control_Stats/HBoxContainer_StarRating/Star3,
	$Control_Stats/HBoxContainer_StarRating/Star4,
	$Control_Stats/HBoxContainer_StarRating/Star5,
]

@export var delivery_arrow: TextureRect
@export var key_sprite: TextureRect
@export var key_on_angle: float = 45.0
@export var key_off_angle: float = -45.0

var manager
var radio: Node
var daynight: Node3D
var _arrow_visible: bool = false
var _smoothed_screen_pos: Vector2 = Vector2.ZERO

func _ready():
	manager = get_node("/root/ScoreAndTimeManager")
	radio = get_tree().get_first_node_in_group("car_radio")
	daynight = get_tree().get_first_node_in_group("daynight")
	if delivery_arrow:
		delivery_arrow.hide()

func _get_active_car() -> VehicleBody3D:
	for c in get_tree().get_nodes_in_group("car"):
		if c.driver_in_car:
			return c
	return null

func _process(_delta):
	if not manager:
		return

	var car = _get_active_car()
	if car:
		speed_label.text = "%03d km/h" % int(car.linear_velocity.length() * 3.6)
		height_label.text = "%dm" % int(car.global_position.y - height_world_zero)

	money_label.text    = "Money: %d" % manager.get_score()
	delivery_label.text = "Deliver to: %s" % manager.get_target_delivery()

	panel_delivery.visible = manager.is_delivering

	if manager.is_delivering:
		timer_label.text  = "%ds" % int(manager.delivery_timer)
		status_label.text = _get_delivery_status()
	else:
		timer_label.text  = ""
		status_label.text = ""

	var rating = manager.get_star_rating()
	for i in stars.size():
		stars[i].modulate.a = 1.0 if i < rating else 0.3

	star_xp_label.text = "starxpmeter: %s" % manager.get_star_xp_progress()

	if radio:
		radio_label.text = radio.get_status()

	if daynight:
		phase_label.text = "%s  %d%%" % [daynight.get_phase(), int(daynight.get_day_percent())]

	_update_key_hud(car)
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
		
func _update_key_hud(car: VehicleBody3D):
	if not key_sprite:
		return
	if car:
		key_sprite.visible = true
		var target_angle = key_on_angle if car.engine_on else key_off_angle
		key_sprite.rotation_degrees = lerp(key_sprite.rotation_degrees, target_angle, 0.15)
	else:
		key_sprite.visible = false

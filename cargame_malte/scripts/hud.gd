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
@onready var panel_parameter = $Panel_Delivery/Panel_Parameter
@onready var special_type    = $Panel_Delivery/Panel_Parameter/SpecialType
@onready var special_status  = $Panel_Delivery/Panel_Parameter/SpecialStatus

@onready var height_label   = $Panel_Car/CurrentHeightLabel
@onready var panel_car           = $Panel_Car
@onready var control_speedometer = $Control_Speedometer
@onready var control_carkey      = $Control_CarKey
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

@export var security_badge_visual: TextureRect

@export var special_failed_label: Label
@export var special_failed_show_time: float = 3.0
@export var dump_package_label: Label

@export var starxp_debug_label: Label
@export var starxp_debug_show_time: float = 2.0

var manager
var daynight: Node3D
var _arrow_visible: bool = false
var _smoothed_screen_pos: Vector2 = Vector2.ZERO
var _failed_timer: float = 0.0
var _was_failed: bool = false

func _ready():
	manager = get_node("/root/ScoreAndTimeManager")
	daynight = get_tree().get_first_node_in_group("daynight")
	if delivery_arrow:
		delivery_arrow.hide()
	if special_failed_label:
		special_failed_label.visible = false
	if dump_package_label:
		dump_package_label.visible = false
	if starxp_debug_label:
		starxp_debug_label.visible = false

func _get_active_car() -> VehicleBody3D:
	for c in get_tree().get_nodes_in_group("car"):
		if c.driver_in_car:
			return c
	return null

func _get_car_radio(car: VehicleBody3D) -> Node:
	if not car:
		return null
	for r in get_tree().get_nodes_in_group("car_radio"):
		if r.get_parent() == car:
			return r
	return null

func _process(delta):
	if not manager:
		return

	var car = _get_active_car()
	var in_car = car != null

	panel_car.visible           = in_car
	control_speedometer.visible = in_car
	control_carkey.visible      = in_car
	radio_label.visible         = in_car

	if car:
		speed_label.text  = "%03d km/h" % int(car.linear_velocity.length() * 3.6)
		height_label.text = "%dm" % int(car.global_position.y - height_world_zero)

		var radio = _get_car_radio(car)
		radio_label.text = radio.get_status() if radio else ""

	money_label.text    = "Money: %d" % manager.get_score()
	delivery_label.text = "Deliver to: %s" % manager.get_target_delivery()

	panel_delivery.visible = manager.is_delivering and not manager.delivery_failed
	_update_special_panel()

	if manager.is_delivering:
		timer_label.text  = "%ds" % int(manager.delivery_timer)
		status_label.text = _get_delivery_status()
	else:
		timer_label.text  = ""
		status_label.text = ""

	var rating = manager.get_star_rating()
	for i in stars.size():
		stars[i].modulate.a = 1.0 if i < rating else 0.3
		
	if security_badge_visual:
		security_badge_visual.visible = manager.has_special_badge

	star_xp_label.text = "starxpmeter: %s" % manager.get_star_xp_progress()

	if daynight:
		phase_label.text = "%s  %d%%" % [daynight.get_phase(), int(daynight.get_day_percent())]

	_update_key_hud(car)
	_update_arrow()
	_update_failure_labels(delta)
	_update_starxp_debug()

func _update_failure_labels(delta: float):
	if manager.delivery_failed and not _was_failed:
		_failed_timer = special_failed_show_time
	_was_failed = manager.delivery_failed

	if _failed_timer > 0.0:
		_failed_timer -= delta

	var showing_failed = _failed_timer > 0.0
	var needs_dump = manager.delivery_failed and manager.current_package != null and not showing_failed

	if special_failed_label:
		special_failed_label.visible = showing_failed
	if dump_package_label:
		dump_package_label.visible = needs_dump

func _update_starxp_debug():
	if not starxp_debug_label:
		return
	var now = Time.get_ticks_msec() / 1000.0
	var elapsed = now - manager.last_xp_delta_time
	if elapsed < starxp_debug_show_time:
		var d = manager.last_xp_delta
		starxp_debug_label.text = "%s%d XP" % ["+" if d > 0 else "", d]
		starxp_debug_label.visible = true
	else:
		starxp_debug_label.visible = false

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
		
func _update_special_panel():
	var pkg = manager.current_package
	if not manager.is_delivering or not pkg or pkg.security_params.is_empty():
		panel_parameter.visible = false
		return
	panel_parameter.visible = true
	special_type.text   = "Special: \"%s\"" % _param_name(pkg.security_params[0])
	special_status.text = "Status: \"%s\"" % _special_status(pkg.security_params[0])

func _param_name(p: int) -> String:
	match p:
		PackageVariation.SecurityParam.FRAGILE:           return "Fragile"
		PackageVariation.SecurityParam.EXPLOSIVE:         return "Explosive"
		PackageVariation.SecurityParam.AFRAID_OF_HEIGHTS: return "Afraid of heights"
		PackageVariation.SecurityParam.TOP_SECRET:        return "Top secret"
		PackageVariation.SecurityParam.FRESH:             return "Fresh"
		PackageVariation.SecurityParam.KEEP_DRY:          return "Keep dry"
	return ""

func _special_status(param: int) -> String:
	if param == PackageVariation.SecurityParam.EXPLOSIVE:
		var left = manager.MAX_BUMPS - manager.bump_count
		return "BOOM!" if left <= 0 else "%d bumps left" % left
	if param == PackageVariation.SecurityParam.TOP_SECRET:
		if manager.delivery_failed:
			return "You have been spotted!"
		if manager.is_being_seen:
			return "Watch out! %.1fs" % (manager.top_secret_critical_time - manager.top_secret_timer)
		return "All good"
	if param == PackageVariation.SecurityParam.AFRAID_OF_HEIGHTS:
		var car = _get_active_car()
		if car and car._is_height_critical:
			return "FREAKING OUT! %.1fs" % (car.height_critical_time - car._height_critical_timer)
		return "All good"
	if param == PackageVariation.SecurityParam.FRESH:
		if manager.delivery_failed:
			return "Spoiled!"
		return "%.1fs until spoiled" % max(0.0, manager.fresh_spoil_time - manager.fresh_timer)
	if param == PackageVariation.SecurityParam.KEEP_DRY:
		if manager.delivery_failed:
			return "Wet!"
		var w = manager.wet_amount
		if w >= 0.66: return "Soggy"
		if w >= 0.33: return "Damp"
		return "Dry"
	return "All good"

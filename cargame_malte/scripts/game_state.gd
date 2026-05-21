extends Node

var level_score: int = 0
var target_delivery: String = ""
var target_delivery_node: Node3D = null
var has_special_badge: bool = false

@export var reference_speed: float = 5.0
@export var very_good_multiplier: float = 0.5
@export var good_multiplier: float = 1.0
@export var bad_multiplier: float = 1.5
@export var very_bad_multiplier: float = 2.0
@export var very_good_payout: int = 20
@export var good_payout: int = 12
@export var bad_payout: int = 6
@export var very_bad_payout: int = 2

@export var debug_start_star_xp: int = 0
@export var debug_start_maxed: bool = true

@export var criminal_xp_penalty: int = 30
@export var special_fail_xp_penalty: int = 40

@export var fresh_spoil_time: float = 60.0
var fresh_timer: float = 0.0

@export var wet_fail_time: float = 4.0
@export var wet_dry_rate: float = 0.001
var wet_amount: float = 0.0

@export var top_secret_critical_time: float = 2.0
var top_secret_timer: float = 0.0
var is_top_secret_critical: bool = false
var is_being_seen: bool = false



var delivery_timer: float = 0.0
var base_delivery_time: float = 0.0
var is_delivering: bool = false
var delivery_failed: bool = false

var star_xp: int = 0
const STAR_THRESHOLDS = [0, 100, 200, 300, 500]

var last_xp_delta: int = 0
var last_xp_delta_time: float = -999.0

const MAX_BUMPS := 3
var current_package: PackageVariation = null
var bump_count: int = 0

func _ready():
	star_xp = debug_start_star_xp
	if debug_start_maxed:
		star_xp = STAR_THRESHOLDS[-1]
		has_special_badge = true

func _process(delta):
	if is_delivering:
		delivery_timer += delta
		if current_package and PackageVariation.SecurityParam.FRESH in current_package.security_params and not delivery_failed:
			fresh_timer += delta
			if fresh_timer >= fresh_spoil_time:
				fail_delivery()
		_check_top_secret(delta)
		_check_keep_dry(delta)

func _check_top_secret(delta):
	var pkg = current_package
	if not pkg or PackageVariation.SecurityParam.TOP_SECRET not in pkg.security_params:
		top_secret_timer = 0.0
		is_top_secret_critical = false
		is_being_seen = false
		return
	if delivery_failed:
		return

	is_being_seen = false
	for cam in get_tree().get_nodes_in_group("road_security_cameras"):
		if cam.sees_target:
			is_being_seen = true
			break

	if is_being_seen:
		top_secret_timer += delta
		is_top_secret_critical = true
		if top_secret_timer >= top_secret_critical_time:
			fail_delivery()
	else:
		top_secret_timer = 0.0
		is_top_secret_critical = false

func _check_keep_dry(delta):
	var pkg = current_package
	if not pkg or PackageVariation.SecurityParam.KEEP_DRY not in pkg.security_params:
		wet_amount = 0.0
		return
	if delivery_failed:
		return

	var in_water = false
	for w in get_tree().get_nodes_in_group("water_areas"):
		if w.has_carrier():
			in_water = true
			break

	if in_water:
		wet_amount = min(1.0, wet_amount + delta / wet_fail_time)
		if wet_amount >= 1.0:
			fail_delivery()
	else:
		wet_amount = max(0.0, wet_amount - delta * wet_dry_rate)
		
		

func add_score(points: int):
	level_score += points

func get_score() -> int:
	return level_score

func set_target_delivery(id: String):
	target_delivery = id

func get_target_delivery() -> String:
	return target_delivery

func set_target_delivery_node(node: Node3D):
	target_delivery_node = node

func start_delivery(distance: float):
	base_delivery_time = distance / reference_speed
	delivery_timer = 0.0
	is_delivering = true
	bump_count = 0
	delivery_failed = false
	wet_amount = 0.0

func complete_delivery() -> int:
	is_delivering = false
	target_delivery_node = null
	current_package = null
	bump_count = 0
	if delivery_timer <= base_delivery_time * very_good_multiplier:
		return very_good_payout
	elif delivery_timer <= base_delivery_time * good_multiplier:
		return good_payout
	elif delivery_timer <= base_delivery_time * bad_multiplier:
		return bad_payout
	else:
		return very_bad_payout

func complete_delivery_with_star_xp() -> int:
	var payout = complete_delivery()
	var xp_delta = {
		very_good_payout: 50,
		good_payout: 25,
		bad_payout: -2,
		very_bad_payout: -10
	}.get(payout, 0)
	_change_star_xp(xp_delta)
	return payout
	


func sell_to_criminal() -> int:
	var payout = 0
	if current_package:
		payout = current_package.black_market_value
	is_delivering = false
	target_delivery = ""
	target_delivery_node = null
	current_package = null
	bump_count = 0
	delivery_failed = false
	_change_star_xp(-criminal_xp_penalty)
	level_score += payout
	return payout

func get_star_rating() -> int:
	var rating = 1
	for i in range(1, STAR_THRESHOLDS.size()):
		if star_xp >= STAR_THRESHOLDS[i]:
			rating = i + 1
	return rating

func get_star_xp_progress() -> String:
	var rating = get_star_rating()
	if rating >= 5:
		return "%d/MAX" % star_xp
	return "%d/%d" % [star_xp, STAR_THRESHOLDS[rating]]

func _change_star_xp(delta: int):
	if delta == 0:
		return
	star_xp = max(0, star_xp + delta)
	last_xp_delta = delta
	last_xp_delta_time = Time.get_ticks_msec() / 1000.0

func reset():
	level_score = 0
	target_delivery = ""
	target_delivery_node = null
	delivery_timer = 0.0
	is_delivering = false
	star_xp = 0
	has_special_badge = false
	current_package = null
	bump_count = 0
	delivery_failed = false
	
func fail_delivery():
	if delivery_failed:
		return
	delivery_failed = true
	_change_star_xp(-special_fail_xp_penalty)

func dump_package():
	is_delivering = false
	target_delivery = ""
	target_delivery_node = null
	current_package = null
	bump_count = 0
	delivery_failed = false

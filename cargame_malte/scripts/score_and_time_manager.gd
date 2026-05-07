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

var delivery_timer: float = 0.0
var base_delivery_time: float = 0.0
var is_delivering: bool = false
var delivery_failed: bool = false

var star_xp: int = 0
const STAR_THRESHOLDS = [0, 100, 200, 300, 500]

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
	star_xp = max(0, star_xp + xp_delta)
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
	star_xp = max(0, star_xp - criminal_xp_penalty)
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
	delivery_failed = true

func dump_package():
	is_delivering = false
	target_delivery = ""
	target_delivery_node = null
	current_package = null
	bump_count = 0
	delivery_failed = false

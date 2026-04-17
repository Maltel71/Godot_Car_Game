extends Node

var level_score: int = 0
var target_delivery: String = ""
var target_delivery_node: Node3D = null

@export var reference_speed: float = 5.0
@export var very_good_multiplier: float = 0.5
@export var good_multiplier: float = 1.0
@export var bad_multiplier: float = 1.5
@export var very_bad_multiplier: float = 2.0
@export var very_good_payout: int = 20
@export var good_payout: int = 12
@export var bad_payout: int = 6
@export var very_bad_payout: int = 2

var delivery_timer: float = 0.0
var base_delivery_time: float = 0.0
var is_delivering: bool = false

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

func complete_delivery() -> int:
	is_delivering = false
	target_delivery_node = null
	if delivery_timer <= base_delivery_time * very_good_multiplier:
		return very_good_payout
	elif delivery_timer <= base_delivery_time * good_multiplier:
		return good_payout
	elif delivery_timer <= base_delivery_time * bad_multiplier:
		return bad_payout
	else:
		return very_bad_payout

func reset():
	level_score = 0
	target_delivery = ""
	target_delivery_node = null
	delivery_timer = 0.0
	is_delivering = false

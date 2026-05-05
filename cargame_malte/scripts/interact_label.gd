extends Label3D

@export var show_distance: float = 4.0
@export var use_place_package: bool = false
@export var use_enter_car: bool = false
@export var use_proximity: bool = false

var _player: Node3D

func _ready():
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	visible = false

func _process(_delta):
	_player = get_tree().get_first_node_in_group("player")
	if not _player:
		visible = false
		return

	var in_range = global_position.distance_to(_player.global_position) < show_distance

	var show = false
	if use_place_package:
		show = show or (in_range and _player.HasPackage)
	if use_enter_car:
		show = show or in_range
	if use_proximity:
		show = show or in_range

	visible = show

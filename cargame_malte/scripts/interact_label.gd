extends Label3D

@export var show_distance: float = 4.0

var _player: Node3D

func _ready():
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	visible = false

func _process(_delta):
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
		return
	visible = global_position.distance_to(_player.global_position) < show_distance

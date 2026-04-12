extends Node3D

@export var height_offset: float = 3.0

var manager: Node
var current_target: Area3D = null

func _ready():
	manager = get_node("/root/ScoreAndTimeManager")

func _process(_delta):
	var target_id = manager.get_target_delivery()
	if target_id == "":
		visible = false
		return

	# Find the matching delivery area by display_name
	if current_target == null or current_target.display_name != target_id:
		current_target = null
		for area in get_tree().get_nodes_in_group("delivery_areas"):
			if area.display_name == target_id:
				current_target = area
				break

	if current_target:
		visible = true
		global_position = current_target.global_position + Vector3.UP * height_offset
	else:
		visible = false

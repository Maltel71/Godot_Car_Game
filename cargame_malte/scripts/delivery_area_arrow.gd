extends Node3D

@export var height_offset: float = 3.0
@export var min_scale: float = 0.5
@export var max_scale: float = 3.0
@export var min_distance: float = 5.0
@export var max_distance: float = 50.0

var manager: Node
var current_target: Area3D = null
var car: Node3D

@onready var sprite: Sprite3D = $Sprite3D

func _ready():
	manager = get_node("/root/ScoreAndTimeManager")
	car = get_tree().get_first_node_in_group("car")

func _process(_delta):
	var target_id = manager.get_target_delivery()
	if target_id == "":
		visible = false
		return

	if current_target == null or current_target.display_name != target_id:
		current_target = null
		for area in get_tree().get_nodes_in_group("delivery_areas"):
			if area is Area3D and "display_name" in area and area.display_name == target_id:
				current_target = area
				break

	if current_target:
		visible = true
		global_position = current_target.global_position + Vector3.UP * height_offset

		if car:
			var dist = global_position.distance_to(car.global_position)
			var t = 1.0 - clamp((dist - min_distance) / (max_distance - min_distance), 0.0, 1.0)
			var s = lerp(max_scale, min_scale, t)
			sprite.pixel_size = s * 0.01
	else:
		visible = false

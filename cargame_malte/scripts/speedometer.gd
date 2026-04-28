extends Control

@export var max_speed_kmh: float = 400.0

@onready var needle = $Needle

func _get_active_car() -> VehicleBody3D:
	for c in get_tree().get_nodes_in_group("car"):
		if c.driver_in_car:
			return c
	return null

func _process(_delta):
	var car = _get_active_car()
	if not car:
		return
	var speed_kmh = car.linear_velocity.length() * 3.6
	var ratio = clamp(speed_kmh / max_speed_kmh, 0.0, 1.0)
	# -90 = pointing left (0), +90 = pointing right (max)
	needle.rotation_degrees = lerp(-90.0, 90.0, ratio)

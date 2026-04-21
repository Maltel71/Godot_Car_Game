extends Control

@export var max_speed_kmh: float = 400.0

@onready var needle = $Needle

var car: VehicleBody3D

func _ready():
	car = get_tree().get_first_node_in_group("car")

func _process(_delta):
	if not car:
		return
	var speed_kmh = car.linear_velocity.length() * 3.6
	var ratio = clamp(speed_kmh / max_speed_kmh, 0.0, 1.0)
	# -90 = pointing left (0), +90 = pointing right (max)
	needle.rotation_degrees = lerp(-90.0, 90.0, ratio)

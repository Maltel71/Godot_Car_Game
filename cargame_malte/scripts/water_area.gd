extends Node3D

var car_in_water: bool = false

func _ready():
	add_to_group("water_areas")
	var area = $Area3D
	area.body_entered.connect(_on_entered)
	area.body_exited.connect(_on_exited)

func _on_entered(body):
	if body is VehicleBody3D:
		car_in_water = true

func _on_exited(body):
	if body is VehicleBody3D:
		car_in_water = false

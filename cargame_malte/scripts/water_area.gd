extends Node3D

var _bodies: Array[Node] = []

func _ready():
	add_to_group("water_areas")
	var area = $Area3D
	area.body_entered.connect(_on_entered)
	area.body_exited.connect(_on_exited)

func _on_entered(body):
	if (body is VehicleBody3D or body.is_in_group("player")) and body not in _bodies:
		_bodies.append(body)

func _on_exited(body):
	_bodies.erase(body)

func has_carrier() -> bool:
	for b in _bodies:
		if is_instance_valid(b) and "HasPackage" in b and b.HasPackage:
			return true
	return false

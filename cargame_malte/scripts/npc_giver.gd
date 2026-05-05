extends CharacterBody3D

@export var waypoints: Array[Area3D] = []
@export var linked_area: Area3D
@export var move_speed: float = 3.0
@export var package_mesh: Node3D

var car = null
var has_package: bool = true
var waypoint_index: int = 0
var going_out: bool = false
var returning: bool = false

func _ready():
	linked_area.body_entered.connect(_on_area_body_entered)
	linked_area.body_exited.connect(_on_area_body_exited)
	$TouchArea.body_entered.connect(_on_body_entered)
	for wp in waypoints:
		wp.body_entered.connect(_on_waypoint_reached)

func _physics_process(delta):
	if package_mesh:
		package_mesh.visible = has_package

	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0

	if going_out:
		if waypoint_index < waypoints.size():
			var wp = waypoints[waypoint_index].global_position
			_move_toward(wp, delta)
			if global_position.distance_to(wp) < 2.0:
				waypoint_index += 1
		elif car:
			_move_toward(car.global_position, delta)
	elif returning:
		if waypoint_index >= 0 and waypoint_index < waypoints.size():
			var wp = waypoints[waypoint_index].global_position
			_move_toward(wp, delta)
			if global_position.distance_to(wp) < 2.0:
				waypoint_index -= 1
				if waypoint_index < 0:
					waypoint_index = 0
					returning = false
					has_package = true
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()

func _move_toward(target: Vector3, delta: float):
	var dir = (target - global_position)
	dir.y = 0.0
	if dir.length() > 0.5:
		dir = dir.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		look_at(global_position + dir, Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

func _on_waypoint_reached(body):
	if body != self:
		return
	if going_out:
		waypoint_index += 1

func _on_area_body_entered(body):
	if body is CharacterBody3D and "HasPackage" in body and not body.HasPackage \
	and not get_node("/root/ScoreAndTimeManager").is_delivering:
		if linked_area.special_office and not get_node("/root/ScoreAndTimeManager").has_special_badge:
			return
		car = body
		going_out = true
		returning = false
		waypoint_index = 0

func _on_area_body_exited(body):
	if body is CharacterBody3D and "HasPackage" in body:
		car = null
		going_out = false
		returning = true
		waypoint_index = clamp(waypoint_index, 0, waypoints.size() - 1)

func _on_body_entered(body):
	if body is CharacterBody3D and "HasPackage" in body and not body.HasPackage \
	and not get_node("/root/ScoreAndTimeManager").is_delivering:
		if not linked_area.play_pickup_sound(body):
			return
		body.HasPackage = true
		has_package = false
		car = null
		going_out = false
		returning = true
		waypoint_index = waypoints.size() - 1

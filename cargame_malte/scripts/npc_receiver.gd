extends CharacterBody3D

@export var waypoints: Array[Node3D] = []
@export var linked_area: Area3D
@export var move_speed: float = 3.0
@export var package_mesh: Node3D

var car: VehicleBody3D = null
var returning: bool = false
var has_package: bool = false
var waypoint_index: int = 0

func _ready():
	linked_area.body_entered.connect(_on_area_body_entered)
	linked_area.body_exited.connect(_on_area_body_exited)
	$TouchArea.body_entered.connect(_on_body_entered)

func _physics_process(delta):
	if package_mesh:
		package_mesh.visible = has_package

	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0

	if car != null and not returning:
		if waypoint_index < waypoints.size():
			var wp = waypoints[waypoint_index].global_position
			_move_toward(wp, delta)
			if global_position.distance_to(wp) < 0.8:
				waypoint_index += 1
		else:
			_move_toward(car.global_position, delta)
	elif returning:
		if waypoint_index >= 0 and waypoints.size() > 0:
			var wp = waypoints[waypoint_index].global_position
			_move_toward(wp, delta)
			if global_position.distance_to(wp) < 0.8:
				waypoint_index -= 1
				if waypoint_index < 0:
					returning = false
					has_package = false
		else:
			returning = false
			has_package = false
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

func _on_area_body_entered(body):
	if body is VehicleBody3D and body.HasPackage and body.assigned_delivery_id == linked_area.name:
		car = body
		returning = false
		waypoint_index = 0

func _on_area_body_exited(body):
	if body is VehicleBody3D:
		car = null
		returning = true
		waypoint_index = waypoints.size() - 1

func _on_body_entered(body):
	if body is VehicleBody3D and body.HasPackage and body.assigned_delivery_id == linked_area.name:
		body.HasPackage = false
		body.assigned_delivery_id = ""
		linked_area.play_delivery_sound()
		has_package = true
		car = null
		returning = true
		waypoint_index = waypoints.size() - 1
		var manager = get_node("/root/ScoreAndTimeManager")
		manager.complete_delivery()
		manager.set_target_delivery("")

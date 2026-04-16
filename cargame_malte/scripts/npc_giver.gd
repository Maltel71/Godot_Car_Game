extends CharacterBody3D

@export var waypoints: Array[Area3D] = []
@export var linked_area: Area3D
@export var move_speed: float = 3.0
@export var package_mesh: Node3D

var car: VehicleBody3D = null
var has_package: bool = true
var waypoint_index: int = 0
var going_out: bool = false
var returning: bool = false

func _ready():
	print("[NPC] _ready called")
	print("[NPC] waypoints count: ", waypoints.size())
	linked_area.body_entered.connect(_on_area_body_entered)
	linked_area.body_exited.connect(_on_area_body_exited)
	$TouchArea.body_entered.connect(_on_body_entered)
	for i in waypoints.size():
		print("[NPC] connecting waypoint ", i, ": ", waypoints[i].name)
		waypoints[i].body_entered.connect(_on_waypoint_reached)

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
			var dist = global_position.distance_to(wp)
			print("[NPC] GOING_OUT >> walking to waypoint ", waypoint_index, " (", waypoints[waypoint_index].name, ") dist: ", snapped(dist, 0.01))
			_move_toward(wp, delta)
			if dist < 0.8:
				print("[NPC] GOING_OUT >> reached waypoint ", waypoint_index, " via distance check")
				waypoint_index += 1
		elif car:
			var dist = global_position.distance_to(car.global_position)
			print("[NPC] GOING_OUT >> all waypoints done, walking to car, dist: ", snapped(dist, 0.01))
			_move_toward(car.global_position, delta)
		else:
			print("[NPC] GOING_OUT >> all waypoints done but no car!")
	elif returning:
		if waypoint_index >= 0 and waypoint_index < waypoints.size():
			var wp = waypoints[waypoint_index].global_position
			var dist = global_position.distance_to(wp)
			print("[NPC] RETURNING >> walking to waypoint ", waypoint_index, " (", waypoints[waypoint_index].name, ") dist: ", snapped(dist, 0.01))
			_move_toward(wp, delta)
			if dist < 0.8:
				print("[NPC] RETURNING >> reached waypoint ", waypoint_index, " via distance check")
				waypoint_index -= 1
				if waypoint_index < 0:
					print("[NPC] RETURNING >> reached home, going IDLE")
					waypoint_index = 0
					returning = false
					has_package = true
		else:
			print("[NPC] RETURNING >> waypoint_index out of range: ", waypoint_index)
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
	print("[NPC] _on_waypoint_reached: ", body.name, " going_out: ", going_out, " returning: ", returning)
	if body != self:
		print("[NPC] _on_waypoint_reached: not self, ignoring")
		return
	if going_out:
		print("[NPC] waypoint signal >> advancing from ", waypoint_index, " to ", waypoint_index + 1)
		waypoint_index += 1
	elif returning:
		print("[NPC] waypoint signal >> reversing from ", waypoint_index, " to ", waypoint_index - 1)
		waypoint_index -= 1
		if waypoint_index < 0:
			print("[NPC] RETURNING >> reached home via signal, going IDLE")
			waypoint_index = 0
			returning = false
			has_package = true

func _on_area_body_entered(body):
	print("[NPC] linked_area body_entered: ", body.name, " is VehicleBody3D: ", body is VehicleBody3D)
	if body is VehicleBody3D:
		print("[NPC] HasPackage: ", body.HasPackage)
	if body is VehicleBody3D and not body.HasPackage:
		print("[NPC] >> starting GOING_OUT")
		car = body
		going_out = true
		returning = false
		waypoint_index = 0

func _on_area_body_exited(body):
	print("[NPC] linked_area body_exited: ", body.name)
	if body is VehicleBody3D:
		print("[NPC] >> car left, switching to RETURNING at waypoint_index: ", waypoint_index)
		car = null
		going_out = false
		returning = true
		waypoint_index = clamp(waypoint_index, 0, waypoints.size() - 1)
		print("[NPC] >> clamped waypoint_index: ", waypoint_index)

func _on_body_entered(body):
	print("[NPC] TouchArea body_entered: ", body.name)
	if body is VehicleBody3D and not body.HasPackage:
		print("[NPC] >> delivering package, switching to RETURNING")
		body.HasPackage = true
		linked_area.play_pickup_sound(body)
		has_package = false
		car = null
		going_out = false
		returning = true
		waypoint_index = waypoints.size() - 1

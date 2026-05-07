extends CharacterBody3D

@export var waypoints: Array[Area3D] = []
@export var linked_area: Area3D
@export var move_speed: float = 3.0
@export var package_mesh: Node3D

@export var money_scene: PackedScene
@export var spawn_height_offset: float = 1.0
@export var spawn_force: float = 5.0

@export var coin_spawn_particles: GPUParticles3D

var car = null
var has_package: bool = false
var waypoint_index: int = 0
var going_out: bool = false
var returning: bool = false

func _ready():
	linked_area.body_entered.connect(_on_area_body_entered)
	linked_area.body_exited.connect(_on_area_body_exited)
	$TouchArea.body_entered.connect(_on_body_entered)
	for wp in waypoints:
		wp.body_entered.connect(_on_waypoint_reached)

func _can_accept(body) -> bool:
	if not (body is CharacterBody3D and "HasPackage" in body and body.HasPackage):
		return false
	if not ("assigned_delivery_id" in body and body.assigned_delivery_id == linked_area.name):
		return false
	return not get_node("/root/ScoreAndTimeManager").delivery_failed

func _physics_process(delta):
	if package_mesh:
		package_mesh.visible = has_package

	# Check if player with package is already in area
	if not going_out and not returning and not car:
		var bodies = linked_area.get_overlapping_bodies()
		for body in bodies:
			if _can_accept(body):
				car = body
				going_out = true
				returning = false
				waypoint_index = 0
				break

	# Abort chase if target no longer holds our package
	if going_out and car and "HasPackage" in car \
	and (not car.HasPackage or car.assigned_delivery_id != linked_area.name):
		car = null
		going_out = false
		returning = true
		waypoint_index = clamp(waypoint_index, 0, waypoints.size() - 1)

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

func _on_waypoint_reached(body):
	if body != self:
		return
	if going_out:
		waypoint_index += 1

func _on_area_body_entered(body):
	if _can_accept(body):
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
	if _can_accept(body):
		body.HasPackage = false
		body.assigned_delivery_id = ""
		linked_area.play_delivery_sound()
		has_package = true
		car = null
		going_out = false
		returning = true
		waypoint_index = waypoints.size() - 1
		var manager = get_node("/root/ScoreAndTimeManager")
		var coin_count = manager.complete_delivery_with_star_xp()
		manager.set_target_delivery("")
		_spawn_coins(coin_count)

func _spawn_coins(count: int):
	if not money_scene:
		return
	for i in count:
		await get_tree().create_timer(0.01 * i).timeout
		var coin = money_scene.instantiate()
		get_tree().current_scene.add_child(coin)
		coin.global_position = global_position + Vector3.UP * spawn_height_offset
		var dir = Vector3(randf_range(-1, 1), 1.0, randf_range(-1, 1)).normalized()
		coin.apply_impulse(dir * spawn_force)
		var torque = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
		coin.apply_torque_impulse(torque * spawn_force * 0.2)
		if coin_spawn_particles:
			coin_spawn_particles.restart()

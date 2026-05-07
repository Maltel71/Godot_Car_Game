extends Node3D

@export var view_range: float = 20.0
@export var view_angle_deg: float = 27.0  ## Half-angle of the cone
@export var line_of_sight_raycast: RayCast3D  ## Optional: blocks vision through walls

var sees_target: bool = false

func _ready():
	add_to_group("road_security_cameras")

func _physics_process(_delta):
	sees_target = _check_sight()

func _check_sight() -> bool:
	var manager = get_node("/root/ScoreAndTimeManager")
	var pkg = manager.current_package
	if not pkg or PackageVariation.SecurityParam.TOP_SECRET not in pkg.security_params:
		return false

	var car := _find_car_with_package()
	if not car:
		return false

	var to_target = car.global_position - global_position
	if to_target.length() > view_range:
		return false

	var forward = -global_transform.basis.z
	if rad_to_deg(forward.angle_to(to_target.normalized())) > view_angle_deg:
		return false

	if line_of_sight_raycast and not _check_line_of_sight(car):
		return false

	return true

func _check_line_of_sight(car: VehicleBody3D) -> bool:
	# 1 center point + 9 evenly spaced around the car silhouette = 10 total
	var offsets: Array[Vector3] = [Vector3.ZERO]
	var x = car.global_transform.basis.x
	var y = car.global_transform.basis.y
	for i in 9:
		var angle = i * TAU / 9.0
		offsets.append(x * cos(angle) + y * sin(angle))

	for offset in offsets:
		var target = car.global_position + offset
		line_of_sight_raycast.target_position = line_of_sight_raycast.to_local(target)
		line_of_sight_raycast.force_raycast_update()
		if not line_of_sight_raycast.is_colliding() or line_of_sight_raycast.get_collider() == car:
			return true
	return false

func _find_car_with_package() -> VehicleBody3D:
	for c in get_tree().get_nodes_in_group("car"):
		if c.HasPackage:
			return c
	return null

extends Node3D

@export var view_range: float = 15.0
@export var view_angle_deg: float = 45.0  ## Half-angle of the cone
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

	if line_of_sight_raycast:
		line_of_sight_raycast.target_position = line_of_sight_raycast.to_local(car.global_position)
		line_of_sight_raycast.force_raycast_update()
		if line_of_sight_raycast.is_colliding() and line_of_sight_raycast.get_collider() != car:
			return false

	return true

func _find_car_with_package() -> VehicleBody3D:
	for c in get_tree().get_nodes_in_group("car"):
		if c.HasPackage:
			return c
	return null

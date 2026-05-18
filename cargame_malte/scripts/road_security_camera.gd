extends Node3D

@export var line_of_sight_raycast: RayCast3D
@export var pivot: Node3D
@export var swivel_angle: float = 45.0
@export var rotate_duration: float = 1.0
@export var pause_duration: float = 1.0

var sees_target: bool = false
var target_in_cone: Node3D = null

func _ready():
	add_to_group("road_security_cameras")
	var area := pivot.get_node("Area3D") as Area3D
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	_start_swivel()

func _start_swivel():
	var tween := create_tween().set_loops()
	tween.tween_property(pivot, "rotation:y", deg_to_rad(swivel_angle), rotate_duration)
	tween.tween_interval(pause_duration)
	tween.tween_property(pivot, "rotation:y", deg_to_rad(-swivel_angle), rotate_duration)
	tween.tween_interval(pause_duration)

func _on_body_entered(body):
	if body is VehicleBody3D or body.is_in_group("player"):
		target_in_cone = body

func _on_body_exited(body):
	if body == target_in_cone:
		target_in_cone = null
		sees_target = false

func _physics_process(_delta):
	if not target_in_cone or not target_in_cone.HasPackage:
		sees_target = false
		return
	var manager = get_node("/root/ScoreAndTimeManager")
	var pkg = manager.current_package
	if not pkg or PackageVariation.SecurityParam.TOP_SECRET not in pkg.security_params:
		sees_target = false
		return
	sees_target = not line_of_sight_raycast or _check_line_of_sight(target_in_cone)

func _check_line_of_sight(target: Node3D) -> bool:
	var offsets: Array[Vector3] = [Vector3.ZERO]
	var x = target.global_transform.basis.x
	var y = target.global_transform.basis.y
	for i in 9:
		var angle = i * TAU / 9.0
		offsets.append(x * cos(angle) + y * sin(angle))

	for offset in offsets:
		var t = target.global_position + offset
		line_of_sight_raycast.target_position = line_of_sight_raycast.to_local(t)
		line_of_sight_raycast.force_raycast_update()
		if not line_of_sight_raycast.is_colliding() or line_of_sight_raycast.get_collider() == target:
			return true
	return false

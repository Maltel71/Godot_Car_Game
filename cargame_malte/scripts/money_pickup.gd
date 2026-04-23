extends RigidBody3D

@export var suction_force_min: float = 5.0
@export var suction_force_max: float = 40.0
@export var suction_ramp_time: float = 3.0
@export var suction_range: float = 10.0
@export var pickup_particles: GPUParticles3D

var car: VehicleBody3D = null
var _time: float = 0.0

func _ready():
	car = get_tree().get_first_node_in_group("car")
	$Area3D.body_entered.connect(_on_body_entered)

func _get_target() -> Node3D:
	if not car:
		return null
	return car if car.driver_in_car else car.current_player

func _physics_process(delta):
	var target = _get_target()
	if not target:
		return
	_time += delta
	var t = clamp(_time / suction_ramp_time, 0.0, 1.0)
	var suction_force = lerp(suction_force_min, suction_force_max, t)
	gravity_scale = lerp(1.0, 0.0, t)
	var dir = (target.global_position - global_position).normalized()
	if t >= 1.0:
		linear_velocity = dir * suction_force_max
	elif global_position.distance_to(target.global_position) < suction_range:
		apply_force(dir * suction_force * (1.0 - global_position.distance_to(target.global_position) / suction_range))

func _on_body_entered(body):
	if body is VehicleBody3D or body is CharacterBody3D:
		get_node("/root/ScoreAndTimeManager").add_score(1)
		if pickup_particles:
			pickup_particles.reparent(get_tree().current_scene)
			pickup_particles.emitting = true
		queue_free()

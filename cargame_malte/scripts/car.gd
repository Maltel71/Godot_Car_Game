extends VehicleBody3D
var max_RPM = 900
var max_torque = 600
var turn_speed = 3
var turn_amount = 0.3
var air_control_pitch_strength = 2000.0
var air_control_yaw_strength = 2000.0
var air_control_roll_strength = 2000.0
var air_control_damping = 0.98
var air_control_fade_time = 2.0
var air_time = 0.0
var is_dead: bool = false
@export var spring_bone_simulator: SpringBoneSimulator3D
@export var exhaust_particles: GPUParticles3D
@export var explosion_particles: GPUParticles3D
@export var rpm_threshold: float = 50.0
@export_group("Flip")
@export var flip_up_impulse: float = 8.0
@export var flip_torque_impulse: float = 5.0
@export var flip_cooldown: float = 2.0
var _flip_timer: float = 0.0

func _physics_process(delta):
	if is_dead:
		return
	
	$CamArm.position = position
	
	_try_flip()
	_flip_timer -= delta
	
	var dir = Input.get_action_strength("Gas") - Input.get_action_strength("Reverse")
	var steering_dir = Input.get_action_strength("Left") - Input.get_action_strength("Right")
	
	var avg_rpm = (abs($wheel_back_left.get_rpm()) + abs($wheel_back_right.get_rpm())) / 2.0
	engine_force = dir * max_torque * (1.0 - avg_rpm / max_RPM)
	steering = lerp(steering, steering_dir * turn_amount, turn_speed * delta)
	brake = 2 if dir == 0 else 0
	
	if exhaust_particles:
		exhaust_particles.emitting = dir != 0
	
	var wheels = [$wheel_front_left, $wheel_front_right, $wheel_back_left, $wheel_back_right]
	var is_airborne = not wheels.any(func(w): return w.is_in_contact())
	
	if is_airborne:
		air_time += delta
		var fade_multiplier = min(air_time / air_control_fade_time, 1.0)
		
		var air_input = Vector3(
			(Input.get_action_strength("Reverse") - Input.get_action_strength("Gas")) * air_control_pitch_strength * fade_multiplier,
			(Input.get_action_strength("Left") - Input.get_action_strength("Right")) * air_control_yaw_strength * fade_multiplier,
			(Input.get_action_strength("RollRight") - Input.get_action_strength("RollLeft")) * air_control_roll_strength * fade_multiplier
		)
		if air_input != Vector3.ZERO:
			apply_torque(global_transform.basis * air_input)
		angular_velocity *= air_control_damping
	else:
		air_time = 0.0

func _try_flip():
	var is_upright = global_transform.basis.y.dot(Vector3.UP) > 0.8
	if is_upright:
		return
	
	if Input.is_action_just_pressed("flip") and _flip_timer <= 0.0:
		apply_central_impulse(Vector3.UP * flip_up_impulse * mass)
		apply_torque_impulse(global_transform.basis.z * flip_torque_impulse * mass)
		_flip_timer = flip_cooldown

func explode() -> void:
	is_dead = true
	
	if explosion_particles:
		explosion_particles.reparent(get_tree().current_scene)
		explosion_particles.restart()
	
	visible = false
	engine_force = 0
	steering = 0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

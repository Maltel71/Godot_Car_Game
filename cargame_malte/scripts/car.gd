extends VehicleBody3D

var max_RPM = 900
var max_torque = 600
var turn_speed = 3
var turn_amount = 0.3

var HasPackage: bool = false

@export var spring_bone_simulator: SpringBoneSimulator3D
@export var exhaust_particles: GPUParticles3D
@export var rpm_threshold: float = 50.0

@export_group("Auto Levelling")
@export var level_strength: float = 5.0  # How hard it corrects the tilt
@export var level_damping: float = 3.0   # How quickly it kills rotation (prevents oscillation)

func _physics_process(delta):
	$CamArm.position = position
	
	var dir = Input.get_action_strength("Gas") - Input.get_action_strength("Reverse")
	var steering_dir = Input.get_action_strength("Left") - Input.get_action_strength("Right")
	
	# Ground controls
	var avg_rpm = (abs($wheel_back_left.get_rpm()) + abs($wheel_back_right.get_rpm())) / 2.0
	engine_force = dir * max_torque * (1.0 - avg_rpm / max_RPM)
	steering = lerp(steering, steering_dir * turn_amount, turn_speed * delta)
	brake = 2 if dir == 0 else 0
	
	# Exhaust particles
	if exhaust_particles:
		exhaust_particles.emitting = dir != 0
	
	# Auto levelling while airborne
	var wheels = [$wheel_front_left, $wheel_front_right, $wheel_back_left, $wheel_back_right]
	var is_airborne = not wheels.any(func(w): return w.is_in_contact())
	
	if is_airborne:
		# Find the tilt axes: cross product of car's up vs world up
		var car_up = global_transform.basis.y
		var world_up = Vector3.UP
		var correction_axis = car_up.cross(world_up)
		
		# Apply corrective torque and damping both through physics
		apply_torque(correction_axis * level_strength * mass)
		apply_torque(-angular_velocity * level_damping * mass)

extends VehicleBody3D

var max_RPM = 900
var max_torque = 600
var turn_speed = 3
var turn_amount = 0.3
@export var spring_bone_simulator: SpringBoneSimulator3D
@export var exhaust_particles: GPUParticles3D
@export var rpm_threshold: float = 50.0

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

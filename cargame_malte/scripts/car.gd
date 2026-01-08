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

func _physics_process(delta):
	$CamArm.position = position
	
	var dir = Input.get_action_strength("Gas") - Input.get_action_strength("Brake")
	var steering_dir = Input.get_action_strength("Left") - Input.get_action_strength("Right")
	
	# Ground controls
	var avg_rpm = (abs($wheel_back_left.get_rpm()) + abs($wheel_back_right.get_rpm())) / 2.0
	engine_force = dir * max_torque * (1.0 - avg_rpm / max_RPM)
	steering = lerp(steering, steering_dir * turn_amount, turn_speed * delta)
	brake = 2 if dir == 0 else 0
	
	# Air controls
	var wheels = [$wheel_front_left, $wheel_front_right, $wheel_back_left, $wheel_back_right]
	var is_airborne = not wheels.any(func(w): return w.is_in_contact())
	
	if is_airborne:
		air_time += delta
		var fade_multiplier = min(air_time / air_control_fade_time, 1.0)
		
		var air_input = Vector3(
			(Input.get_action_strength("Brake") - Input.get_action_strength("Gas")) * air_control_pitch_strength * fade_multiplier,
			(Input.get_action_strength("Left") - Input.get_action_strength("Right")) * air_control_yaw_strength * fade_multiplier,
			(Input.get_action_strength("RollRight") - Input.get_action_strength("RollLeft")) * air_control_roll_strength * fade_multiplier
		)
		if air_input != Vector3.ZERO:
			apply_torque(global_transform.basis * air_input)
		angular_velocity *= air_control_damping
	else:
		air_time = 0.0

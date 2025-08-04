extends VehicleBody3D
var max_RPM = 900
var max_torque = 600
var turn_speed = 3
var turn_amount = 0.3
# Air control variables
var air_control_strength = 2000.0  # How strong the air control is
var air_control_damping = 0.98  # Damping to prevent excessive spinning

func _physics_process(delta):
	$CamArm.position = position
	
	var dir = Input.get_action_strength("Gas") - Input.get_action_strength("Brake")
	var steering_dir = Input.get_action_strength("Left") - Input.get_action_strength("Right")
	
	var RPM_left = abs($wheel_back_left.get_rpm())
	var RPM_right = abs($wheel_back_right.get_rpm())
	var RPM = (RPM_left + RPM_right) / 2.0
	var torque = dir * max_torque * (1.0 - RPM / max_RPM)
	engine_force = torque
	steering = lerp(steering, steering_dir * turn_amount, turn_speed * delta)
	
	if dir == 0:
		brake = 2
	
	# Check if car is in the air (not touching ground)
	if is_in_air():
		apply_air_control(delta)

func is_in_air() -> bool:
	# Check if any wheel is touching the ground
	# Based on your scene structure, the actual VehicleWheel3D nodes are:
	var wheels = [$wheel_front_left, $wheel_front_right, $wheel_back_left, $wheel_back_right]
	for wheel in wheels:
		if wheel.is_in_contact():
			return false
	return true

func apply_air_control(delta):
	var air_input = Vector3.ZERO
	
	# Get input for air control using the same actions as your car controls
	# INVERTED: W now tilts backward, S tilts forward
	if Input.is_action_pressed("Gas"):  # W key - tilt backward (inverted)
		air_input.x -= 1.0
	if Input.is_action_pressed("Brake"):  # S key - tilt forward (inverted)
		air_input.x += 1.0
	if Input.is_action_pressed("Left"):  # A key - rotate left (yaw)
		air_input.y += 1.0
	if Input.is_action_pressed("Right"):  # D key - rotate right (yaw)
		air_input.y -= 1.0
	
	# Apply air control torque
	if air_input != Vector3.ZERO:
		# Transform the torque from local space to world space
		var local_torque = air_input * air_control_strength
		var world_torque = global_transform.basis * local_torque
		apply_torque(world_torque)
		print("In air! Applying local torque: ", local_torque, " -> world torque: ", world_torque)  # Debug print
	
	# Apply some damping to prevent excessive spinning
	angular_velocity *= air_control_damping

extends VehicleBody3D

var max_RPM = 900
var max_torque = 800
var turn_speed = 3
var turn_amount = 0.3

var HasPackage: bool = false
var assigned_delivery_id: String = ""

@export var spring_bone_simulator: SpringBoneSimulator3D
@export var exhaust_particles: GPUParticles3D
@export var rpm_threshold: float = 50.0

@export_group("Auto Levelling")
@export var level_strength: float = 5.0
@export var level_damping: float = 3.0

@export_group("Flip")
@export var flip_up_impulse: float = 8.0
@export var flip_torque_impulse: float = 5.0
@export var flip_cooldown: float = 2.0

@export_group("Enter/Exit")
@export var player_scene: PackedScene
@export var exit_offset: Vector3 = Vector3(-1.5, 0, 0)
@export var car_camera: Camera3D
@export var driver_mesh: Node3D
@export var max_exit_speed: float = 1.5
@export var exit_hold_time: float = 1.5
@export var handbrake_sound: AudioStream
@export var handbrake_audio_player: AudioStreamPlayer3D

var _flip_timer: float = 0.0
var driver_in_car: bool = true
var current_player: Node3D = null
var _slow_timer: float = 0.0
var _doors_locked: bool = true

func _physics_process(delta):
	$CamArm.position = position
	$PackageMesh.visible = HasPackage
	
	if driver_mesh:
		driver_mesh.visible = driver_in_car

	if driver_in_car:
		# Track how long the car has been nearly still
		if linear_velocity.length() < max_exit_speed:
			_slow_timer += delta
		else:
			_slow_timer = 0.0
		_doors_locked = _slow_timer < exit_hold_time

		if Input.is_action_just_pressed("enter_exit") and not _doors_locked:
			_exit_car()
			return
	else:
		# Parked: hold handbrake
		engine_force = 0
		brake = 5
		steering = 0
		return

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
		var car_up = global_transform.basis.y
		var correction_axis = car_up.cross(Vector3.UP)
		apply_torque(correction_axis * level_strength * mass)
		apply_torque(-angular_velocity * level_damping * mass)

func _try_flip():
	var is_upright = global_transform.basis.y.dot(Vector3.UP) > 0.8
	if is_upright:
		return

	if Input.is_action_just_pressed("flip") and _flip_timer <= 0.0:
		apply_central_impulse(Vector3.UP * flip_up_impulse * mass)
		apply_torque_impulse(global_transform.basis.z * flip_torque_impulse * mass)
		_flip_timer = flip_cooldown

func _exit_car():
	if not player_scene:
		return
	if handbrake_sound and handbrake_audio_player:
		handbrake_audio_player.stream = handbrake_sound
		handbrake_audio_player.play()
	driver_in_car = false
	current_player = player_scene.instantiate()
	get_tree().current_scene.add_child(current_player)
	current_player.global_position = global_position + global_transform.basis * exit_offset
	if current_player.has_method("set_car_ref"):
		current_player.set_car_ref(self)

func enter_car():
	if current_player:
		current_player.queue_free()
		current_player = null
	if car_camera:
		car_camera.make_current()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	await get_tree().process_frame
	driver_in_car = true
	_slow_timer = 0.0
	_doors_locked = true

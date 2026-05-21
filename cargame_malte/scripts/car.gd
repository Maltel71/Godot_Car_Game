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
@export var starts_with_driver: bool = false
@export var player_scene: PackedScene
@export var exit_offset: Vector3 = Vector3(-1.5, 0, 0)
@export var car_camera: Camera3D
@export var driver_mesh: Node3D
@export var max_exit_speed: float = 1.5
@export var exit_hold_time: float = 1.5

@export_group("Audio")
@export var handbrake_sound: AudioStream
@export var handbrake_audio_player: AudioStreamPlayer3D
@export var engine_toggle_audio_player: AudioStreamPlayer3D
@export var engine_start_sound: AudioStream
@export var engine_stop_sound: AudioStream
@export var exhaust_particles_idle: GPUParticles3D

@export_group("Explosive")
@export var hard_bump_threshold: float = 7.00
@export var explosion_particles: GPUParticles3D
@export var explosion_audio_player: AudioStreamPlayer3D
@export var explosion_sound: AudioStream

@export_group("Explosive")
@export var broken_package_scene: PackedScene
@export var package_spawn_point: Node3D

@export_group("Afraid of Heights")
@export var height_raycast: RayCast3D
@export var max_height_tolerance: float = 8.0
@export var height_critical_time: float = 3.0
@export var animal_scene: PackedScene
@export var animal_spawn_point: Node3D
var _height_critical_timer: float = 0.0
var _is_height_critical: bool = false

var _flip_timer: float = 0.0
var driver_in_car: bool = false
var current_player: Node3D = null
var _slow_timer: float = 0.0
var _doors_locked: bool = true
var engine_on: bool = false

func _ready():
	if starts_with_driver:
		driver_in_car = true
		engine_on = true
		if car_camera:
			car_camera.make_current()
	if exhaust_particles:
		exhaust_particles.emitting = false
	if exhaust_particles_idle:
		exhaust_particles_idle.emitting = engine_on
	_sync_lights()
	body_entered.connect(_on_body_collision)

func _physics_process(delta):
	$CamArm.position = position
	$PackageMesh.visible = HasPackage

	if driver_mesh:
		driver_mesh.visible = driver_in_car

	if driver_in_car:
		if Input.is_action_just_pressed("toggle_engine"):
			engine_on = !engine_on
			_on_engine_toggled()

		if linear_velocity.length() < max_exit_speed:
			_slow_timer += delta
		else:
			_slow_timer = 0.0
		_doors_locked = _slow_timer < exit_hold_time

		if Input.is_action_just_pressed("enter_exit") and not _doors_locked:
			_exit_car()
			return

		_check_afraid_of_heights(delta)

	else:
		# Parked: hold handbrake
		engine_force = 0
		brake = 5
		steering = 0
		if exhaust_particles:
			exhaust_particles.emitting = false
		if exhaust_particles_idle:
			exhaust_particles_idle.emitting = engine_on
		return

	if not engine_on:
		engine_force = 0
		brake = 2
		steering = 0
		if exhaust_particles:
			exhaust_particles.emitting = false
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
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.queue_free()
	current_player = null
	if car_camera:
		car_camera.make_current()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	await get_tree().process_frame
	driver_in_car = true
	_slow_timer = 0.0
	_doors_locked = true

func _on_engine_toggled():
	_sync_lights()
	if exhaust_particles_idle:
		exhaust_particles_idle.emitting = engine_on
	if engine_toggle_audio_player:
		var s: AudioStream = engine_start_sound if engine_on else engine_stop_sound
		if s:
			engine_toggle_audio_player.stream = s
			engine_toggle_audio_player.play()

func _sync_lights():
	for light in find_children("*", "Light3D", true):
		if light.is_in_group("headlight"):
			continue
		light.visible = engine_on

func _on_body_collision(_body):
	if not HasPackage:
		return
	var manager = get_node("/root/ScoreAndTimeManager")
	var pkg = manager.current_package
	if not pkg:
		return
	if linear_velocity.length() < hard_bump_threshold:
		return

	var is_explosive = PackageVariation.SecurityParam.EXPLOSIVE in pkg.security_params
	var is_fragile = PackageVariation.SecurityParam.FRAGILE in pkg.security_params
	if not is_explosive and not is_fragile:
		return

	manager.bump_count += 1
	if manager.bump_count >= manager.MAX_BUMPS:
		if is_explosive:
			_explode()
		elif is_fragile:
			_break_package()

func _explode():
	if explosion_particles:
		explosion_particles.restart()
	if explosion_audio_player and explosion_sound:
		explosion_audio_player.stream = explosion_sound
		explosion_audio_player.play()
	HasPackage = false
	assigned_delivery_id = ""
	var manager = get_node("/root/ScoreAndTimeManager")
	manager.fail_delivery()
	manager.current_package = null
	manager.bump_count = 0
	manager.is_delivering = false
	manager.set_target_delivery("")
	manager.set_target_delivery_node(null)

func _break_package():
	if broken_package_scene and package_spawn_point:
		var broken = broken_package_scene.instantiate()
		get_tree().current_scene.add_child(broken)
		broken.global_transform = package_spawn_point.global_transform
	HasPackage = false
	assigned_delivery_id = ""
	var manager = get_node("/root/ScoreAndTimeManager")
	manager.fail_delivery()
	manager.current_package = null
	manager.bump_count = 0
	manager.is_delivering = false
	manager.set_target_delivery("")
	manager.set_target_delivery_node(null)

func _check_afraid_of_heights(delta):
	if not HasPackage or not height_raycast:
		_height_critical_timer = 0.0
		_is_height_critical = false
		return
	var manager = get_node("/root/ScoreAndTimeManager")
	var pkg = manager.current_package
	if not pkg or PackageVariation.SecurityParam.AFRAID_OF_HEIGHTS not in pkg.security_params:
		_height_critical_timer = 0.0
		_is_height_critical = false
		return

	height_raycast.force_raycast_update()
	var height := 0.0
	if height_raycast.is_colliding():
		height = global_position.distance_to(height_raycast.get_collision_point())
	else:
		height = max_height_tolerance + 1.0  # no ground = too high

	if height > max_height_tolerance:
		_height_critical_timer += delta
		_is_height_critical = true
		if _height_critical_timer >= height_critical_time:
			_animal_freakout()
	else:
		_height_critical_timer = 0.0
		_is_height_critical = false

func _animal_freakout():
	_break_package()
	if animal_scene and animal_spawn_point:
		var animal = animal_scene.instantiate()
		get_tree().current_scene.add_child(animal)
		animal.global_position = animal_spawn_point.global_position

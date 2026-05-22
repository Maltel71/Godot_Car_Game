extends CharacterBody3D

@export var walk_speed: float = 3.0
@export var run_speed: float = 6.0
@export var jump_velocity: float = 5.0
@export var sens_h: float = 0.2
@export var sens_v: float = 0.2

@export var enter_distance: float = 3.0
@export var package_pickup_distance: float = 2.0
@export var package_interaction_node_path: NodePath = "packagedistancepoint"
@export var player_camera: Camera3D
@export var package_mesh: Node3D
@export var flashlight: Node3D

@onready var camera_mount: Node3D = $camera_mount
@onready var visuals: Node3D = $visuals
@onready var spring_arm: SpringArm3D = $camera_mount/SpringArm3D

@export var flashlight_pitch_offset: float = -0.3

var car_ref: VehicleBody3D = null
var HasPackage: bool = false
var assigned_delivery_id: String = ""

func _ready():
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if player_camera:
		player_camera.make_current()
	if package_mesh:
		package_mesh.visible = false
	if flashlight:
		flashlight.visible = false

func set_car_ref(car: VehicleBody3D):
	car_ref = car
	spring_arm.add_excluded_object(car.get_rid())

func _find_nearest_car(max_dist: float) -> VehicleBody3D:
	var nearest: VehicleBody3D = null
	var best := max_dist
	for c in get_tree().get_nodes_in_group("car"):
		var point = c.get_node_or_null(package_interaction_node_path)
		var pos = point.global_position if point else c.global_position
		var d := global_position.distance_to(pos)
		if d < best:
			best = d
			nearest = c
	return nearest

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * sens_h))
		visuals.rotate_y(deg_to_rad(event.relative.x * sens_h))
		camera_mount.rotate_x(deg_to_rad(-event.relative.y * sens_v))
		camera_mount.rotation.x = clamp(camera_mount.rotation.x, deg_to_rad(-85), deg_to_rad(20))
	
	if event.is_action_pressed("flashlight"):
		if flashlight:
			flashlight.visible = !flashlight.visible

func _physics_process(delta):
	if package_mesh:
		package_mesh.visible = HasPackage
	if flashlight:
			flashlight.rotation.x = camera_mount.rotation.x + flashlight_pitch_offset

	# Track the nearest car for interaction
	car_ref = _find_nearest_car(max(enter_distance, package_pickup_distance))

	# Get package interaction point or fallback to car center
	var interaction_point = car_ref.get_node_or_null(package_interaction_node_path) if car_ref else null
	var check_position = interaction_point.global_position if interaction_point else (car_ref.global_position if car_ref else global_position)

	# Put package in car
	if Input.is_action_just_pressed("interact") and car_ref \
	and HasPackage and global_position.distance_to(check_position) < package_pickup_distance:
		car_ref.HasPackage = true
		car_ref.assigned_delivery_id = assigned_delivery_id
		HasPackage = false
		assigned_delivery_id = ""
		return

	# Pick up package from car
	if Input.is_action_just_pressed("interact") and car_ref \
	and car_ref.HasPackage and global_position.distance_to(check_position) < package_pickup_distance:
		HasPackage = true
		assigned_delivery_id = car_ref.assigned_delivery_id
		car_ref.HasPackage = false
		car_ref.assigned_delivery_id = ""
		return

	# Enter car
	if Input.is_action_just_pressed("enter_exit") and car_ref \
	and not HasPackage \
	and global_position.distance_to(car_ref.global_position) < enter_distance:
		if flashlight:
			flashlight.visible = false
		car_ref.enter_car()
		return

	if not is_on_floor():
		velocity += get_gravity() * 2 * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var speed = run_speed if Input.is_action_pressed("run") else walk_speed
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		visuals.look_at(position - direction)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

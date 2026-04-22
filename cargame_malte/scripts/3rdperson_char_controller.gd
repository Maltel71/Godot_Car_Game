extends CharacterBody3D

@export var walk_speed: float = 3.0
@export var run_speed: float = 6.0
@export var jump_velocity: float = 5.0
@export var sens_h: float = 0.2
@export var sens_v: float = 0.2

@export var enter_distance: float = 3.0
@export var player_camera: Camera3D

@onready var camera_mount: Node3D = $camera_mount
@onready var visuals: Node3D = $visuals

var car_ref: VehicleBody3D = null

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if player_camera:
		player_camera.make_current()

func set_car_ref(car: VehicleBody3D):
	car_ref = car

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * sens_h))
		visuals.rotate_y(deg_to_rad(event.relative.x * sens_h))
		camera_mount.rotate_x(deg_to_rad(-event.relative.y * sens_v))
		camera_mount.rotation.x = clamp(camera_mount.rotation.x, deg_to_rad(-60), deg_to_rad(20))

func _physics_process(delta):
	if Input.is_action_just_pressed("enter_exit") and car_ref \
	and global_position.distance_to(car_ref.global_position) < enter_distance:
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

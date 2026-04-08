extends SpringArm3D

var MouseSensitivity = 0.1

# Dynamic zoom settings
@export var car_node: VehicleBody3D
@export var min_zoom: float = 3.0
@export var max_zoom: float = 5.0
@export var zoom_speed: float = 1.0
@export var speed_threshold: float = 30.0

# Auto-reset settings
@export var idle_timeout: float = 2.0      # Seconds of no mouse input before reset starts
@export var reset_speed: float = 3.0       # How fast the camera snaps back (higher = snappier)
@export var mouse_threshold: float = 1.0   # Mouse movement needed to count as "active"

var _idle_timer: float = 0.0
var _is_resetting: bool = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_as_top_level(true)
	spring_length = min_zoom
	if not car_node:
		car_node = get_parent()

func _input(event):
	if event is InputEventMouseMotion:
		var motion = event.relative.length()
		if motion > mouse_threshold:
			# User is actively moving — cancel any reset and apply rotation
			_idle_timer = 0.0
			_is_resetting = false

			rotation_degrees.x -= event.relative.y * MouseSensitivity
			rotation_degrees.x = clamp(rotation_degrees.x, -90.0, -10.0)
			rotation_degrees.y -= event.relative.x * MouseSensitivity
			rotation_degrees.y = wrapf(rotation_degrees.y, 0.0, 360.0)

func _process(delta):
	if not car_node:
		return

	# Tick idle timer
	_idle_timer += delta
	if _idle_timer >= idle_timeout:
		_is_resetting = true

	# Smoothly reset to behind the car
	if _is_resetting:
		var car_y = wrapf(rad_to_deg(car_node.rotation.y) + 180.0, 0.0, 360.0)
		var target_x = -15.0  # Default vertical angle behind car

		# Shortest path for Y to avoid spinning the long way around
		var diff = wrapf(car_y - rotation_degrees.y, -180.0, 180.0)
		rotation_degrees.y = wrapf(rotation_degrees.y + diff * reset_speed * delta, 0.0, 360.0)
		rotation_degrees.x = lerp(rotation_degrees.x, target_x, reset_speed * delta)

	# Dynamic zoom based on speed
	var car_speed = car_node.linear_velocity.length()
	var speed_ratio = min(car_speed / speed_threshold, 1.0)
	var target_zoom = lerp(min_zoom, max_zoom, speed_ratio)
	spring_length = lerp(spring_length, target_zoom, zoom_speed * delta)

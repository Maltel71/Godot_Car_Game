extends SpringArm3D

var MouseSensitivity = 0.1

# Dynamic zoom settings
@export var car_node: VehicleBody3D  # Reference to your car
@export var min_zoom: float = 3.0    # Closest distance
@export var max_zoom: float = 5.0   # Furthest distance  
@export var zoom_speed: float = 1.0  # How fast zoom changes
@export var speed_threshold: float = 30.0  # Max speed for full zoom

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_as_top_level(true)
	
	# Set initial zoom
	spring_length = min_zoom
	
	# Auto-find car if not assigned
	if not car_node:
		car_node = get_parent()

func _input(event):
	if event is InputEventMouseMotion:
		rotation_degrees.x -= event.relative.y * MouseSensitivity
		rotation_degrees.x = clamp(rotation_degrees.x, -90.0, -10.0)
		rotation_degrees.y -= event.relative.x * MouseSensitivity
		rotation_degrees.y = wrapf(rotation_degrees.y, 0.0, 360.0)

func _process(delta):
	if not car_node:
		return
	
	# Get car speed
	var car_speed = car_node.linear_velocity.length()
	
	# Calculate target zoom based on speed
	var speed_ratio = min(car_speed / speed_threshold, 1.0)
	var target_zoom = lerp(min_zoom, max_zoom, speed_ratio)
	
	# Smoothly adjust spring length (camera distance)
	spring_length = lerp(spring_length, target_zoom, zoom_speed * delta)

extends RigidBody3D

# --- Tuning ---
@export var throttle_force    : float = 18.0
@export var pitch_torque      : float = 6.0
@export var roll_torque       : float = 5.0
@export var yaw_torque        : float = 4.0
@export var tilt_fwd_force    : float = 12.0
@export var drag              : float = 2.5
@export var mouse_sensitivity : float = 0.003

# --- State ---
var throttle_input : float = 0.0
var yaw_input      : float = 0.0
var pitch_input    : float = 0.0
var roll_input     : float = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		pitch_input = event.relative.y * mouse_sensitivity
		roll_input  = -event.relative.x * mouse_sensitivity

func _physics_process(delta: float) -> void:
	throttle_input = Input.get_axis("throttle_down", "throttle_up")
	yaw_input      = Input.get_axis("yaw_left", "yaw_right")

	var up  := basis.y
	var fwd := basis.z

	apply_central_force(up * throttle_input * throttle_force)

	var flat_fwd := Vector3(fwd.x, 0, fwd.z).normalized()
	apply_central_force(flat_fwd * tilt_fwd_force * throttle_input)

	apply_torque(basis.x * pitch_input * pitch_torque)
	apply_torque(basis.z * roll_input  * roll_torque)
	apply_torque(basis.y * -yaw_input  * yaw_torque)

	apply_central_force(-linear_velocity * drag)

	# Reset every frame — mouse gives deltas, not held state
	pitch_input = 0.0
	roll_input  = 0.0

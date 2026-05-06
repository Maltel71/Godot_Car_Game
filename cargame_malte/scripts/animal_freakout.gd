extends CharacterBody3D

@export var launch_force: float = 10.0
@export var run_speed: float = 8.0
@export var despawn_time: float = 10.0

var _launched: bool = false
var _run_dir: Vector3 = Vector3.ZERO

func _ready():
	velocity.y = launch_force
	_run_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	get_tree().create_timer(despawn_time).timeout.connect(queue_free)

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		if not _launched:
			_launched = true
		velocity.x = _run_dir.x * run_speed
		velocity.z = _run_dir.z * run_speed
		var look_target = global_position + _run_dir
		look_at(look_target, Vector3.UP)

	move_and_slide()

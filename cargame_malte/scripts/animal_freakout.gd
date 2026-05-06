extends CharacterBody3D

@export var launch_force: float = 10.0
@export var run_speed: float = 8.0
@export var despawn_time: float = 10.0
@export var gravity_scale: float = 3.0
@export var wiggle_strength: float = 0.4
@export var wiggle_speed: float = 2.0
@export var direction_change_interval: float = 1.2

var _launched: bool = false
var _run_dir: Vector3 = Vector3.ZERO
var _wiggle_dir: Vector3 = Vector3.ZERO
var _dir_timer: float = 0.0

func _ready():
	velocity.y = launch_force
	_run_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	get_tree().create_timer(despawn_time).timeout.connect(queue_free)

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * gravity_scale * delta
	else:
		if not _launched:
			_launched = true

		_dir_timer -= delta
		if _dir_timer <= 0.0:
			_run_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
			_dir_timer = randf_range(direction_change_interval * 0.5, direction_change_interval * 1.5)

		var raw_wiggle = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * wiggle_strength
		_wiggle_dir = _wiggle_dir.lerp(raw_wiggle, delta * wiggle_speed)
		var move_dir = (_run_dir + _wiggle_dir).normalized()

		velocity.x = move_dir.x * run_speed
		velocity.z = move_dir.z * run_speed
		look_at(global_position + move_dir, Vector3.UP)

	move_and_slide()

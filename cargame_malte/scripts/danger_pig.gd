extends CharacterBody3D

enum State { WANDER, CHASE }

@export var move_speed: float = 2.5
@export var turn_speed: float = 3.0

@export_group("Chase")
@export var chase_speed: float = 6.0
@export var chase_turn_speed: float = 8.0
@export var attack_area: Area3D

@export_group("Direction Change")
@export var direction_change_min: float = 1.5
@export var direction_change_max: float = 4.0

@export_group("Wiggle")
@export var wiggle_strength: float = 0.3
@export var wiggle_speed: float = 5.0

var _state: State = State.WANDER
var _move_direction: Vector3 = Vector3.FORWARD
var _direction_timer: float = 0.0
var _wiggle_time: float = 0.0
var _target: Node3D = null

const GRAVITY: float = -9.8


func _ready() -> void:
	_pick_new_direction()
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_body_entered)
		attack_area.body_exited.connect(_on_attack_area_body_exited)


func _physics_process(delta: float) -> void:
	match _state:
		State.WANDER:
			_process_wander(delta)
		State.CHASE:
			_process_chase(delta)
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
	
	move_and_slide()


func _process_wander(delta: float) -> void:
	_wiggle_time += delta * wiggle_speed
	var wiggle_offset = sin(_wiggle_time) * wiggle_strength
	
	var target_basis = Basis.looking_at(_move_direction, Vector3.UP)
	var wiggled_basis = target_basis.rotated(Vector3.UP, wiggle_offset)
	global_transform.basis = global_transform.basis.slerp(wiggled_basis, turn_speed * delta)
	
	velocity.x = _move_direction.x * move_speed
	velocity.z = _move_direction.z * move_speed
	
	_direction_timer -= delta
	if _direction_timer <= 0.0:
		_pick_new_direction()


func _process_chase(delta: float) -> void:
	if not is_instance_valid(_target):
		_enter_wander()
		return
	
	var to_target = (_target.global_position - global_position)
	to_target.y = 0.0
	
	if to_target.length_squared() > 0.01:
		_move_direction = to_target.normalized()
	
	_wiggle_time += delta * wiggle_speed
	var wiggle_offset = sin(_wiggle_time) * wiggle_strength
	
	var target_basis = Basis.looking_at(_move_direction, Vector3.UP)
	var wiggled_basis = target_basis.rotated(Vector3.UP, wiggle_offset)
	global_transform.basis = global_transform.basis.slerp(wiggled_basis, chase_turn_speed * delta)
	
	velocity.x = _move_direction.x * chase_speed
	velocity.z = _move_direction.z * chase_speed


func _enter_wander() -> void:
	_state = State.WANDER
	_target = null
	_pick_new_direction()


func _on_attack_area_body_entered(body: Node3D) -> void:
	if body is VehicleBody3D:
		_state = State.CHASE
		_target = body


func _on_attack_area_body_exited(body: Node3D) -> void:
	if body == _target:
		_enter_wander()


func _pick_new_direction() -> void:
	var angle = randf() * TAU
	_move_direction = Vector3(sin(angle), 0.0, cos(angle))
	_direction_timer = randf_range(direction_change_min, direction_change_max)

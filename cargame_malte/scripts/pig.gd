extends CharacterBody3D

@export var move_speed: float = 2.5
@export var turn_speed: float = 3.0

@export_group("Direction Change")
@export var direction_change_min: float = 1.5
@export var direction_change_max: float = 4.0

@export_group("Wiggle")
@export var wiggle_strength: float = 0.3
@export var wiggle_speed: float = 5.0

@export_group("Hit Effect")
@export var hit_area: Area3D
@export var hit_particles: GPUParticles3D
@export var hit_sound: AudioStream
@export_range(-80, 24) var hit_sound_volume_db: float = 0.0

var _move_direction: Vector3 = Vector3.FORWARD
var _direction_timer: float = 0.0
var _wiggle_time: float = 0.0
var _is_dead: bool = false

const GRAVITY: float = -9.8


func _ready() -> void:
	_pick_new_direction()
	if hit_area:
		hit_area.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	
	_wiggle_time += delta * wiggle_speed
	var wiggle_offset = sin(_wiggle_time) * wiggle_strength
	
	var target_basis = Basis.looking_at(_move_direction, Vector3.UP)
	var wiggled_basis = target_basis.rotated(Vector3.UP, wiggle_offset)
	global_transform.basis = global_transform.basis.slerp(wiggled_basis, turn_speed * delta)
	
	var move_vec = _move_direction * move_speed
	velocity.x = move_vec.x
	velocity.z = move_vec.z
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
	
	move_and_slide()
	
	_direction_timer -= delta
	if _direction_timer <= 0.0:
		_pick_new_direction()


func _on_body_entered(body: Node3D) -> void:
	if _is_dead:
		return
	if not body is VehicleBody3D:
		return
	
	_is_dead = true
	
	# Detach and play particles so they survive the pig being freed
	if hit_particles:
		hit_particles.reparent(get_tree().current_scene)
		hit_particles.restart()
	
	# Detach and play sound so it survives the pig being freed
	if hit_sound:
		var player = AudioStreamPlayer3D.new()
		get_tree().current_scene.add_child(player)
		player.global_position = global_position
		player.bus = "sfx"
		player.volume_db = hit_sound_volume_db
		player.stream = hit_sound
		player.play()
		player.finished.connect(func(): player.queue_free())
	
	queue_free()


func _pick_new_direction() -> void:
	var angle = randf() * TAU
	_move_direction = Vector3(sin(angle), 0.0, cos(angle))
	_direction_timer = randf_range(direction_change_min, direction_change_max)

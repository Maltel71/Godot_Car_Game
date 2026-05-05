extends CharacterBody3D

@export var waypoints: Array[Node3D] = []  ## A=spawn, B=waypoints[0], C=waypoints[1]
@export var move_speed: float = 3.0
@export var wait_time_at_end: float = 8.0
@export var package_mesh: Node3D
@export var sell_sound: AudioStream
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

@export var money_scene: PackedScene
@export var spawn_height_offset: float = 1.0
@export var spawn_force: float = 5.0
@export var coin_spawn_particles: GPUParticles3D

enum State { IDLE, GOING_OUT, WAITING, RETURNING }

var state: State = State.IDLE
var waypoint_index: int = 0
var wait_timer: float = 0.0
var player_in_range: Node3D = null

func _ready():
	$InteractArea.body_entered.connect(_on_body_entered)
	$InteractArea.body_exited.connect(_on_body_exited)
	if package_mesh:
		package_mesh.visible = false

func _unhandled_input(event):
	if event.is_action_pressed("interact") and player_in_range and state == State.IDLE:
		if not player_in_range.HasPackage:
			return
		_sell_package()

func _sell_package():
	var manager = get_node("/root/ScoreAndTimeManager")
	if not manager.is_delivering:
		return
	player_in_range.HasPackage = false
	player_in_range.assigned_delivery_id = ""
	if package_mesh:
		package_mesh.visible = true
	if sell_sound and audio_player:
		audio_player.stream = sell_sound
		audio_player.play()
	_spawn_coins(manager.sell_to_criminal())
	state = State.GOING_OUT
	waypoint_index = 0

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0

	match state:
		State.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0
		State.GOING_OUT:
			if waypoint_index < waypoints.size():
				var wp = waypoints[waypoint_index].global_position
				_move_toward(wp)
				if global_position.distance_to(wp) < 1.5:
					waypoint_index += 1
			else:
				state = State.WAITING
				wait_timer = wait_time_at_end
				velocity.x = 0.0
				velocity.z = 0.0
		State.WAITING:
			velocity.x = 0.0
			velocity.z = 0.0
			wait_timer -= delta
			if wait_timer <= 0.0:
				if package_mesh:
					package_mesh.visible = false
				state = State.RETURNING
				waypoint_index = waypoints.size() - 1
		State.RETURNING:
			if waypoint_index >= 0:
				var wp = waypoints[waypoint_index].global_position
				_move_toward(wp)
				if global_position.distance_to(wp) < 1.5:
					waypoint_index -= 1
			else:
				state = State.IDLE

	move_and_slide()

func _move_toward(target: Vector3):
	var dir = target - global_position
	dir.y = 0.0
	if dir.length() > 0.5:
		dir = dir.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		look_at(global_position + dir, Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

func _on_body_entered(body):
	if body is CharacterBody3D and "HasPackage" in body:
		player_in_range = body

func _on_body_exited(body):
	if body == player_in_range:
		player_in_range = null

func _spawn_coins(count: int):
	if not money_scene:
		return
	for i in count:
		await get_tree().create_timer(0.01 * i).timeout
		var coin = money_scene.instantiate()
		get_tree().current_scene.add_child(coin)
		coin.global_position = global_position + Vector3.UP * spawn_height_offset
		var dir = Vector3(randf_range(-1, 1), 1.0, randf_range(-1, 1)).normalized()
		coin.apply_impulse(dir * spawn_force)
		if coin_spawn_particles:
			coin_spawn_particles.restart()

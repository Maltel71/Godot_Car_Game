extends CharacterBody3D

@export var point_a: Node3D
@export var linked_area: Area3D
@export var move_speed: float = 3.0

var car: VehicleBody3D = null
var returning: bool = false

func _ready():
	linked_area.body_entered.connect(_on_area_body_entered)
	linked_area.body_exited.connect(_on_area_body_exited)
	$TouchArea.body_entered.connect(_on_body_entered)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0

	if car != null and not returning:
		_move_toward(car.global_position, delta)
	elif returning:
		_move_toward(point_a.global_position, delta)
		if global_position.distance_to(point_a.global_position) < 1.5:
			returning = false
			velocity.x = 0.0
			velocity.z = 0.0
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()

func _move_toward(target: Vector3, delta: float):
	var dir = (target - global_position)
	dir.y = 0.0
	if dir.length() > 1.5:
		dir = dir.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		look_at(global_position + dir, Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

func _on_area_body_entered(body):
	if body is VehicleBody3D and body.HasPackage and body.assigned_delivery_id == linked_area.name:
		car = body
		returning = false

func _on_area_body_exited(body):
	if body is VehicleBody3D:
		car = null
		returning = true

func _on_body_entered(body):
	if body is VehicleBody3D and body.HasPackage and body.assigned_delivery_id == linked_area.name:
		body.HasPackage = false
		body.assigned_delivery_id = ""
		linked_area.play_delivery_sound()
		var manager = get_node("/root/ScoreAndTimeManager")
		manager.set_target_delivery("")
		car = null
		returning = true

extends RigidBody3D

@export var suction_force: float = 15.0
@export var suction_range: float = 10.0

var car: VehicleBody3D = null

func _ready():
	car = get_tree().get_first_node_in_group("car")
	$Area3D.body_entered.connect(_on_body_entered)

func _physics_process(delta):
	if not car:
		return
	var dist = global_position.distance_to(car.global_position)
	if dist < suction_range:
		var dir = (car.global_position - global_position).normalized()
		apply_force(dir * suction_force * (1.0 - dist / suction_range))

func _on_body_entered(body):
	if body is VehicleBody3D:
		get_node("/root/ScoreAndTimeManager").add_score(1)
		queue_free()

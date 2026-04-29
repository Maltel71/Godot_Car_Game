extends Area3D

@export var spawn_point: Node3D

var player_in_range: Node3D = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = body

func _on_body_exited(body):
	if body == player_in_range:
		player_in_range = null

func _unhandled_input(event):
	if event.is_action_pressed("enter_exit") and player_in_range and spawn_point:
		player_in_range.global_position = spawn_point.global_position
		player_in_range.velocity = Vector3.ZERO
		get_viewport().set_input_as_handled()

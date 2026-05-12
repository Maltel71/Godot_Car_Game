extends StaticBody3D

@onready var area: Area3D = $Area3D
var player_in_range: Node3D = null

func _ready():
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = body

func _on_body_exited(body):
	if body == player_in_range:
		player_in_range = null

func _unhandled_input(event):
	if event.is_action_pressed("interact") and player_in_range and player_in_range.HasPackage:
		player_in_range.HasPackage = false
		player_in_range.assigned_delivery_id = ""
		get_node("/root/ScoreAndTimeManager").dump_package()
		get_viewport().set_input_as_handled()

extends Area3D

@export var win_menu_scene: PackedScene

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body is VehicleBody3D:
		show_win_menu()

func show_win_menu():
	# Stop timer FIRST
	var manager = get_node("/root/ScoreAndTimeManager")
	manager.stop_timer()
	
	# Hide highscore UI
	var highscore_ui = get_tree().get_first_node_in_group("highscore_ui")
	if highscore_ui:
		highscore_ui.hide()
	
	var win_menu = win_menu_scene.instantiate()
	get_tree().current_scene.add_child(win_menu)
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

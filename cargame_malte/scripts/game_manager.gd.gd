extends Node

func _ready():
	set_process_input(true)

func _input(event):
	# Check if Enter key is pressed for restart
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER):
		restart_scene()

func restart_scene():
	get_tree().paused = false
	get_node("/root/ScoreAndTimeManager").reset()
	get_tree().reload_current_scene()

func pause_game():
	get_tree().paused = true

func unpause_game():
	get_tree().paused = false

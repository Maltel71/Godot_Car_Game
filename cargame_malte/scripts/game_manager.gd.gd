extends Node

func _ready():
	# Make sure this node can receive input
	set_process_input(true)

func _input(event):
	# Check if Enter key is pressed for restart
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER):
		restart_scene()
	
	# Check if Escape key is pressed for exit
	elif event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		quit_game()

func restart_scene():
	# Get the current scene and reload it
	get_tree().reload_current_scene()

func quit_game():
	# Exit the game
	get_tree().quit()

# Optional: Add other game management functions
func pause_game():
	get_tree().paused = true

func unpause_game():
	get_tree().paused = false

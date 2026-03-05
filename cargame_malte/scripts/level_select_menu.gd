extends Control

@export var level_scenes: Array[String] = []
@export var hover_sound: AudioStream
@export_range(-80, 24) var hover_volume: float = 0.0

@onready var main_menu_button = $Panel/VBoxContainer/MainMenuButton
@onready var grid_container = $Panel/GridContainer # Reference the parent container
@onready var audio_player = $AudioStreamPlayer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if audio_player:
		audio_player.bus = "sfx"
	
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	if hover_sound:
		main_menu_button.mouse_entered.connect(_on_button_hover)

	# This loop handles ALL buttons inside the GridContainer automatically
	var buttons = grid_container.get_children()
	for i in range(buttons.size()):
		var btn = buttons[i]
		
		# Connect the click signal with the button's index
		btn.pressed.connect(_on_level_pressed.bind(i))
		
		# Connect the hover signal
		if hover_sound:
			btn.mouse_entered.connect(_on_button_hover)

func _on_level_pressed(index: int):
	# Check if the index exists in your array and isn't empty
	if index < level_scenes.size() and level_scenes[index] != "":
		# MusicManager.stop_music() # Ensure your MusicManager singleton exists!
		get_tree().change_scene_to_file(level_scenes[index])
	else:
		print("Warning: No scene assigned for level index: ", index)

func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://ui/menus/start_menu.tscn")

func _on_button_hover():
	if hover_sound and audio_player:
		audio_player.stream = hover_sound
		audio_player.volume_db = hover_volume
		audio_player.play()

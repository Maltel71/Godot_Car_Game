extends Control

@export var hover_sound: AudioStream
@export_range(-80, 24) var hover_volume: float = 0.0

@onready var play_again_button = $Panel/VBoxContainer/PlayAgainButton
@onready var main_menu_button = $Panel/VBoxContainer/MainMenuButton
@onready var quit_button = $Panel/VBoxContainer/QuitButton
@onready var audio_player = $AudioStreamPlayer

var current_level_path: String = ""

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var manager = get_node("/root/ScoreAndTimeManager")
	$Panel/VBoxContainer/Time.text = "Time: %.2f" % manager.get_time()
	$Panel/VBoxContainer/Score.text = "Score: %d" % manager.get_score()
	
	if audio_player:
		audio_player.bus = "sfx"
	
	# Get current scene path
	current_level_path = get_tree().current_scene.scene_file_path
	
	# Connect signals
	play_again_button.pressed.connect(_on_play_again_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	if hover_sound:
		play_again_button.mouse_entered.connect(_on_button_hover)
		main_menu_button.mouse_entered.connect(_on_button_hover)
		quit_button.mouse_entered.connect(_on_button_hover)

func _on_play_again_pressed():
	get_tree().paused = false
	var manager = get_node("/root/ScoreAndTimeManager")
	manager.reset()
	manager.start_timer()
	get_tree().reload_current_scene()

func _on_main_menu_pressed():
	get_tree().paused = false
	var manager = get_node("/root/ScoreAndTimeManager")
	manager.reset()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://menus/start_menu.tscn")

func _on_quit_pressed():
	get_tree().quit()

func _on_button_hover():
	if hover_sound and audio_player:
		audio_player.stream = hover_sound
		audio_player.volume_db = hover_volume
		audio_player.play()

# start_menu.gd
extends Control

@export var game_scene_path: String = "res://levels/car_level_1.tscn"  # Update this path
@export var hover_sound: AudioStream
@export_range(-80, 24) var hover_volume: float = 0.0
@export_range(-80, 24) var menu_music_volume: float = 0.0

@onready var play_button = $VBoxContainer/PlayButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var audio_player = $AudioStreamPlayer

@export var menu_music: AudioStream

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if audio_player:
		audio_player.bus = "SFX"
	
	play_button.pressed.connect(_on_play_pressed)  # Renamed
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	if hover_sound:
		play_button.mouse_entered.connect(_on_button_hover)
		settings_button.mouse_entered.connect(_on_button_hover)
		quit_button.mouse_entered.connect(_on_button_hover)
		
		# Start menu music
	if menu_music:
		MusicManager.play_menu_music(menu_music)
		MusicManager.music_player.volume_db = menu_music_volume

func _on_play_pressed():
	MusicManager.stop_music()
	get_tree().change_scene_to_file("res://levels/level_2.tscn")

func _on_settings_pressed():
	get_tree().change_scene_to_file("res://menus/settings_menu.tscn")

func _on_quit_pressed():
	get_tree().quit()

func _on_button_hover():
	if hover_sound and audio_player:
		audio_player.stream = hover_sound
		audio_player.volume_db = hover_volume
		audio_player.play()
		
		
		

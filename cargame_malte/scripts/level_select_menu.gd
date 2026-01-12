extends Control

@export var level_scenes: Array[String] = []
@export var hover_sound: AudioStream
@export_range(-80, 24) var hover_volume: float = 0.0

@onready var main_menu_button = $Panel/VBoxContainer/MainMenuButton
@onready var level_1 = $Panel/GridContainer/Level_1
@onready var level_2 = $Panel/GridContainer/Level_2
@onready var level_3 = $Panel/GridContainer/Level_3
@onready var level_4 = $Panel/GridContainer/Level_4
@onready var level_5 = $Panel/GridContainer/Level_5
@onready var level_6 = $Panel/GridContainer/Level_6
@onready var audio_player = $AudioStreamPlayer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if audio_player:
		audio_player.bus = "sfx"
	
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	level_1.pressed.connect(_on_level_pressed.bind(0))
	level_2.pressed.connect(_on_level_pressed.bind(1))
	level_3.pressed.connect(_on_level_pressed.bind(2))
	level_4.pressed.connect(_on_level_pressed.bind(3))
	level_5.pressed.connect(_on_level_pressed.bind(4))
	level_6.pressed.connect(_on_level_pressed.bind(5))
	
	if hover_sound:
		main_menu_button.mouse_entered.connect(_on_button_hover)
		level_1.mouse_entered.connect(_on_button_hover)
		level_2.mouse_entered.connect(_on_button_hover)
		level_3.mouse_entered.connect(_on_button_hover)
		level_4.mouse_entered.connect(_on_button_hover)
		level_5.mouse_entered.connect(_on_button_hover)
		level_6.mouse_entered.connect(_on_button_hover)

func _on_level_pressed(index: int):
	if index < level_scenes.size() and level_scenes[index] != "":
		MusicManager.stop_music()
		get_tree().change_scene_to_file(level_scenes[index])

func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://menus/start_menu.tscn")

func _on_button_hover():
	if hover_sound and audio_player:
		audio_player.stream = hover_sound
		audio_player.volume_db = hover_volume
		audio_player.play()

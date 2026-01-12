# settings_menu.gd
extends Control

@export var hover_sound: AudioStream
@export var slider_drag_sound: AudioStream
@export_range(-80, 24) var hover_volume: float = 0.0
@export_range(-80, 24) var slider_drag_volume: float = 0.0
@export var slider_sound_delay: float = 0.1

@onready var master_volume = $Panel/VBoxContainer/MasterVolume
@onready var music_volume = $Panel/VBoxContainer/MusicVolume
@onready var sfx_volume = $Panel/VBoxContainer/SFXVolume
@onready var ok_button = $Panel/VBoxContainer/OKButton
@onready var audio_player = $AudioStreamPlayer

var can_play_slider_sound: bool = true

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if audio_player:
		audio_player.bus = "sfx"
	
	# Load current volumes into sliders (convert to 0-100 range)
	master_volume.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))) * 100.0
	music_volume.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("music"))) * 100.0
	sfx_volume.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("sfx"))) * 100.0
	
	# Connect signals
	master_volume.value_changed.connect(_on_master_volume_changed)
	music_volume.value_changed.connect(_on_music_volume_changed)
	sfx_volume.value_changed.connect(_on_sfx_volume_changed)
	ok_button.pressed.connect(_on_ok_pressed)
	
	# Connect value_changed to play sound while dragging
	if slider_drag_sound:
		master_volume.value_changed.connect(_on_slider_value_changed)
		music_volume.value_changed.connect(_on_slider_value_changed)
		sfx_volume.value_changed.connect(_on_slider_value_changed)
	
	if hover_sound:
		ok_button.mouse_entered.connect(_on_button_hover)
		master_volume.mouse_entered.connect(_on_button_hover)
		music_volume.mouse_entered.connect(_on_button_hover)
		sfx_volume.mouse_entered.connect(_on_button_hover)

func _on_master_volume_changed(value: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value / 100.0))

func _on_music_volume_changed(value: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("music"), linear_to_db(value / 100.0))

func _on_sfx_volume_changed(value: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("sfx"), linear_to_db(value / 100.0))

func _on_ok_pressed():
	get_tree().change_scene_to_file("res://menus/start_menu.tscn")

func _on_button_hover():
	if hover_sound and audio_player:
		audio_player.stream = hover_sound
		audio_player.volume_db = hover_volume
		audio_player.play()

func _on_slider_value_changed(_value: float):
	if slider_drag_sound and audio_player and can_play_slider_sound:
		audio_player.stream = slider_drag_sound
		audio_player.volume_db = slider_drag_volume
		audio_player.play()
		can_play_slider_sound = false
		await get_tree().create_timer(slider_sound_delay).timeout
		can_play_slider_sound = true

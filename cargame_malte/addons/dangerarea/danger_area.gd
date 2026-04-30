# danger_area.gd
extends Node3D

@export var explosion_sound: AudioStream
@export_range(-80, 24) var explosion_volume: float = 0.0
@export var restart_delay: float = 3.0

@onready var area = $Area3D
@onready var audio_player = AudioStreamPlayer3D.new()

func _ready():
	add_child(audio_player)
	audio_player.bus = "sfx"
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not body is VehicleBody3D:
		return
	
	body.explode()
	
	if explosion_sound:
		audio_player.stream = explosion_sound
		audio_player.volume_db = explosion_volume
		audio_player.play()
	
	await get_tree().create_timer(restart_delay).timeout
	get_tree().reload_current_scene()

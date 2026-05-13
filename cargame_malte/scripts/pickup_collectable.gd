extends Node3D

@export var house_item: Node3D
@export var pickup_sound: AudioStream
@export_range(-80, 24) var pickup_volume: float = 0.0

@onready var area: Area3D = $Area3D
@onready var audio_player := AudioStreamPlayer3D.new()

var player_in_range: Node3D = null

func _ready():
	add_child(audio_player)
	audio_player.bus = "sfx"
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	if house_item:
		house_item.visible = false

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = body

func _on_body_exited(body):
	if body == player_in_range:
		player_in_range = null

func _unhandled_input(event):
	if event.is_action_pressed("interact") and player_in_range:
		get_viewport().set_input_as_handled()
		_collect()

func _collect():
	if house_item:
		house_item.visible = true
	for child in get_children():
		if child is MeshInstance3D:
			child.visible = false
	if pickup_sound:
		audio_player.stream = pickup_sound
		audio_player.volume_db = pickup_volume
		audio_player.play()
		await audio_player.finished
	queue_free()

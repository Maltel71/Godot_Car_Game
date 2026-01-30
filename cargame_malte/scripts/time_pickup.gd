extends Area3D

@export var time_value: float = 5.0  # Seconds to add
@export var pickup_sound: AudioStream
@export_range(-80, 24) var pickup_volume: float = 0.0

@onready var audio_player = AudioStreamPlayer3D.new()

func _ready():
	body_entered.connect(_on_body_entered)
	
	add_child(audio_player)
	audio_player.bus = "sfx"

func _on_body_entered(body):
	if body is VehicleBody3D:
		collect()

func collect():
	var manager = get_node("/root/ScoreAndTimeManager")
	manager.add_time(time_value)
	
	if pickup_sound:
		audio_player.stream = pickup_sound
		audio_player.volume_db = pickup_volume
		audio_player.play()
		# Hide all MeshInstance3D children
		for child in get_children():
			if child is MeshInstance3D:
				child.visible = false
		if has_node("CollisionShape3D"):
			$CollisionShape3D.disabled = true
		await audio_player.finished
	
	queue_free()

extends Area3D

@export var pickup_sound: AudioStream
@onready var audio_player = $AudioStreamPlayer3D

func play_pickup_sound():
	if pickup_sound:
		audio_player.stream = pickup_sound
		audio_player.play()

extends Area3D

@export var delivery_sound: AudioStream
@onready var audio_player = $AudioStreamPlayer3D

func play_delivery_sound():
	if delivery_sound:
		audio_player.stream = delivery_sound
		audio_player.play()

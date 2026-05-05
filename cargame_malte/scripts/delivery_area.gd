extends Area3D
 
@export var display_name: String = "House 1"
@export var zone: int = 1 ## 1=Countryside, 2=Caves, 3=MilitaryBase, 4=RoyalIsland, 5=SecretLab
@export var delivery_sound: AudioStream
@onready var audio_player = $AudioStreamPlayer3D
 
func play_delivery_sound():
	if delivery_sound:
		audio_player.stream = delivery_sound
		audio_player.play()

extends Node

var music_player: AudioStreamPlayer

func _ready():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.bus = "music"
	
	# Initialize volumes once at game start
	if AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")) == 0.0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(0.5))
	if AudioServer.get_bus_volume_db(AudioServer.get_bus_index("music")) == 0.0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("music"), linear_to_db(0.5))
	if AudioServer.get_bus_volume_db(AudioServer.get_bus_index("sfx")) == 0.0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("sfx"), linear_to_db(0.5))

func play_menu_music(music: AudioStream):
	if music_player.stream != music:
		music_player.stream = music
	if not music_player.playing:
		music_player.play()

func stop_music():
	music_player.stop()

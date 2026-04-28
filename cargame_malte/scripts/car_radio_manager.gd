extends Node

@export var channels: Array[RadioChannel] = []
@export var search_sound: AudioStream
@export var search_duration: float = 0.5
@export var radio_emitter_3d: Node3D  # Position where 3D sound emits from (can be your AudioStreamPlayer3D node)
@export var max_distance_3d: float = 15.0

var radio_on: bool = false
var current_channel: int = 0
var is_searching: bool = false

var _players_2d: Array[AudioStreamPlayer] = []
var _players_3d: Array[AudioStreamPlayer3D] = []
var _track_indices: Array[int] = []
var _search_player: AudioStreamPlayer
var car: VehicleBody3D
var _last_inside_car: bool = true

func _ready():
	car = get_parent()
	_search_player = AudioStreamPlayer.new()
	_search_player.bus = "music"
	add_child(_search_player)

	for i in channels.size():
		var player_2d = AudioStreamPlayer.new()
		player_2d.bus = "music"
		player_2d.volume_db = -80.0
		add_child(player_2d)
		_players_2d.append(player_2d)
		
		var player_3d = AudioStreamPlayer3D.new()
		player_3d.bus = "music"
		player_3d.volume_db = -80.0
		player_3d.max_distance = max_distance_3d
		if radio_emitter_3d:
			radio_emitter_3d.add_child(player_3d)
		else:
			add_child(player_3d)
		_players_3d.append(player_3d)
		
		_track_indices.append(0)
		player_2d.finished.connect(_on_track_finished.bind(i))
		_play_track(i)

func _play_track(channel_idx: int):
	var ch = channels[channel_idx]
	if ch.tracks.is_empty():
		return
	var stream = ch.tracks[_track_indices[channel_idx]]
	_players_2d[channel_idx].stream = stream
	_players_3d[channel_idx].stream = stream
	_players_2d[channel_idx].play()
	_players_3d[channel_idx].play()

func _on_track_finished(channel_idx: int):
	var ch = channels[channel_idx]
	_track_indices[channel_idx] = (_track_indices[channel_idx] + 1) % ch.tracks.size()
	_play_track(channel_idx)

var _last_engine_on: bool = false

func _process(_delta):
	if car.driver_in_car != _last_inside_car or car.engine_on != _last_engine_on:
		_last_inside_car = car.driver_in_car
		_last_engine_on = car.engine_on
		_update_volumes()

func _input(event):
	if not car.driver_in_car or not car.engine_on:
		return
	if event.is_action_pressed("car_radio"):
		radio_on = !radio_on
		_update_volumes()
	if event.is_action_pressed("car_radio_channel") and radio_on and not is_searching:
		_switch_channel()

func _switch_channel():
	is_searching = true
	_mute_all()
	if search_sound:
		_search_player.stream = search_sound
		_search_player.play()
	await get_tree().create_timer(search_duration).timeout
	current_channel = (current_channel + 1) % channels.size()
	is_searching = false
	_update_volumes()

func _update_volumes():
	var inside_car = car.driver_in_car
	var powered = car.engine_on
	for i in _players_2d.size():
		var is_active = radio_on and powered and i == current_channel and not is_searching
		_players_2d[i].volume_db = 0.0 if (is_active and inside_car) else -80.0
		_players_3d[i].volume_db = 0.0 if (is_active and not inside_car) else -80.0
	
	var music_bus = AudioServer.get_bus_index("music")
	AudioServer.set_bus_effect_enabled(music_bus, 0, not inside_car)

func _mute_all():
	for p in _players_2d:
		p.volume_db = -80.0
	for p in _players_3d:
		p.volume_db = -80.0

func get_status() -> String:
	if not radio_on:
		return "Radio: Off"
	if is_searching:
		return "Searching..."
	var ch = channels[current_channel]
	var idx = _track_indices[current_channel]
	if idx < ch.track_names.size() and ch.track_names[idx] != "":
		return ch.track_names[idx]
	return ch.channel_name

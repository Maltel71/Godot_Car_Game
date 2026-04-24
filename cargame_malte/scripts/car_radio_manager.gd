extends Node

@export var channels: Array[RadioChannel] = []
@export var search_sound: AudioStream
@export var search_duration: float = 0.5

var radio_on: bool = false
var current_channel: int = 0
var is_searching: bool = false

var _players: Array[AudioStreamPlayer] = []
var _track_indices: Array[int] = []
var _search_player: AudioStreamPlayer
var car: VehicleBody3D

func _ready():
	car = get_parent()
	_search_player = AudioStreamPlayer.new()
	_search_player.bus = "music"
	add_child(_search_player)

	for i in channels.size():
		var player = AudioStreamPlayer.new()
		player.bus = "music"
		player.volume_db = -80.0
		add_child(player)
		_players.append(player)
		_track_indices.append(0)
		player.finished.connect(_on_track_finished.bind(i))
		_play_track(i)

func _play_track(channel_idx: int):
	var ch = channels[channel_idx]
	if ch.tracks.is_empty():
		return
	_players[channel_idx].stream = ch.tracks[_track_indices[channel_idx]]
	_players[channel_idx].play()

func _on_track_finished(channel_idx: int):
	var ch = channels[channel_idx]
	_track_indices[channel_idx] = (_track_indices[channel_idx] + 1) % ch.tracks.size()
	_play_track(channel_idx)

func _input(event):
	if not car.driver_in_car:
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
	for i in _players.size():
		_players[i].volume_db = 0.0 if (radio_on and i == current_channel and not is_searching) else -80.0

func _mute_all():
	for p in _players:
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

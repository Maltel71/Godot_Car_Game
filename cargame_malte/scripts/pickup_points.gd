extends Area3D

@export var score_value: int = 100
@export var pickup_sound: AudioStream
@export_range(-80, 24) var pickup_volume: float = 0.0

@onready var audio_player = AudioStreamPlayer3D.new()

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Setup audio player
	add_child(audio_player)
	audio_player.bus = "sfx"

func _on_body_entered(body):
	if body is VehicleBody3D:
		collect()

func collect():
	# Add score
	var manager = get_node("/root/ScoreAndTimeManager")
	manager.add_score(score_value)
	
	# Play sound if assigned
	if pickup_sound:
		audio_player.stream = pickup_sound
		audio_player.volume_db = pickup_volume  # Set volume
		audio_player.play()
		# Hide mesh but keep node alive for sound
		$env_prop_coin1_mesh_01_v1.visible = false
		$CollisionShape3D.disabled = true
		await audio_player.finished
	
	queue_free()

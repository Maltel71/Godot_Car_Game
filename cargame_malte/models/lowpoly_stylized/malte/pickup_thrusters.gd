extends Area3D

@export var thruster_duration: float = 5.0
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
	print("Collect function called")
	var thrusters = get_tree().get_nodes_in_group("thrusters")
	print("Found ", thrusters.size(), " thrusters in group")
	
	for thruster in thrusters:
		print("Thruster name: ", thruster.name)
		print("Has activate_powerup method: ", thruster.has_method("activate_powerup"))
		if thruster.has_method("activate_powerup"):
			print("Calling activate_powerup with duration: ", thruster_duration)
			thruster.activate_powerup(thruster_duration)
			print("Thruster activated!")
	
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

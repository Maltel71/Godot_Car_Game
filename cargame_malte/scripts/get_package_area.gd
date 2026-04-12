extends Area3D

@export var delivery_areas: Array[Area3D] = []
@export var pickup_sound: AudioStream
@onready var audio_player = $AudioStreamPlayer3D

func play_pickup_sound(car: VehicleBody3D):
	if delivery_areas.size() > 0:
		var picked = delivery_areas.pick_random()
		car.assigned_delivery_id = picked.name
		var manager = get_node("/root/ScoreAndTimeManager")
		manager.set_target_delivery(picked.display_name)
		manager.set_target_delivery_node(picked)
		var distance = global_position.distance_to(picked.global_position)
		manager.start_delivery(distance)
	if pickup_sound:
		audio_player.stream = pickup_sound
		audio_player.play()

extends Area3D
 
@export var available_packages: Array[PackageVariation] = []
@export var special_office: bool = false
@export var pickup_sound: AudioStream
@onready var audio_player = $AudioStreamPlayer3D
 
func play_pickup_sound(character) -> bool:
	var manager = get_node("/root/ScoreAndTimeManager")
	if manager.is_delivering:
		return false

	var star_rating = manager.get_star_rating()
	var picked = PackageManager.pick_package(available_packages, star_rating, special_office)
	if not picked:
		return false

	var zone_areas = PackageManager.find_zone_delivery_areas(picked.delivery_zone)
	if zone_areas.is_empty():
		return false

	var target = zone_areas.pick_random()
	character.assigned_delivery_id = target.name
	manager.set_target_delivery(target.display_name)
	manager.set_target_delivery_node(target)
	var distance = global_position.distance_to(target.global_position)
	manager.start_delivery(distance)
	manager.current_package = picked

	if pickup_sound:
		audio_player.stream = pickup_sound
		audio_player.play()
	return true
 

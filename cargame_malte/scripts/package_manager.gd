extends Node
## Autoload: PackageManager
 
const ZONE_STAR_REQ := {1: 1, 2: 2, 3: 3, 4: 4, 5: 5}
 
var last_picked: PackageVariation = null
 
func pick_package(pool: Array[PackageVariation], star_rating: int, special: bool) -> PackageVariation:
	var has_badge = get_node("/root/ScoreAndTimeManager").has_special_badge
	var valid: Array[PackageVariation] = []
	for p in pool:
		if p.is_special() != special:
			continue
		if special and not has_badge:
			continue
		if star_rating < ZONE_STAR_REQ.get(p.delivery_zone, 1):
			continue
		if p == last_picked and pool.size() > 1:
			continue
		valid.append(p)
 
	if valid.is_empty():
		return null
 
	var total := 0.0
	for p in valid:
		total += p.weight
	var roll := randf() * total
	for p in valid:
		roll -= p.weight
		if roll <= 0.0:
			last_picked = p
			return p
 
	last_picked = valid.back()
	return valid.back()
 
func find_zone_delivery_areas(zone: int) -> Array[Area3D]:
	var result: Array[Area3D] = []
	for area in get_tree().get_nodes_in_group("delivery_areas"):
		if area is Area3D and "zone" in area and area.zone == zone:
			result.append(area)
	return result

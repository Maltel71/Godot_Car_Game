class_name PackageVariation
extends Resource
 
enum SecurityParam { FRAGILE, EXPLOSIVE, AFRAID_OF_HEIGHTS, TOP_SECRET, FRESH, KEEP_DRY }
 
@export var package_name: String = "Package"
@export var delivery_zone: int = 1 ## 1-5, matches delivery_area.zone
@export var security_params: Array[SecurityParam] = []
@export var weight: float = 1.0
@export var black_market_value: int = 5
 
func is_special() -> bool:
	return not security_params.is_empty()

@tool
extends Path3D

## When enabled, the road is unselectable in 3D and snaps back if changed.
@export var lock_road: bool = false:
	set(v):
		lock_road = v
		if lock_road: _snap_data = {"t": global_transform, "c": curve.duplicate()}
		notify_property_list_changed()

var _snap_data: Dictionary = {}

# --- Editor Interaction ---
func _editor_can_edit() -> bool: return !lock_road
func _ignore_raycast() -> bool: return lock_road

# --- Enforcement ---
func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() or not lock_road or _snap_data.is_empty():
		return

	# Revert Transform
	if global_transform != _snap_data.t:
		global_transform = _snap_data.t
	
	# Revert Curve (Only if changed to save performance)
	if curve != _snap_data.c:
		curve = _snap_data.c

extends Node3D

@export var thrust_force: float = 5000.0
@export var visual: Node3D
@export var particle_effect: GPUParticles3D
@export var puff_effect: GPUParticles3D
@export var activate_action: String = "ui_select"  # Set per-instance in the Inspector

var parent_body: VehicleBody3D
var thruster_enabled: bool = false
var was_thrusting: bool = false

func _ready():
	# Search up the tree for VehicleBody3D
	var node = get_parent()
	while node and not node is VehicleBody3D:
		node = node.get_parent()
	parent_body = node as VehicleBody3D

	if visual:
		visual.visible = false
	if particle_effect:
		particle_effect.emitting = false
	set_physics_process(true)

func _input(event):
	if parent_body and "driver_in_car" in parent_body and not parent_body.driver_in_car:
		return
	if parent_body and "engine_on" in parent_body and not parent_body.engine_on:
		return
	# Toggle thruster on/off with the assigned button
	if event.is_action_pressed("thruster_toggle"):
		thruster_enabled = not thruster_enabled
		if visual:
			visual.visible = thruster_enabled
		if not thruster_enabled and particle_effect:
			particle_effect.emitting = false

func _physics_process(delta):
	if not parent_body:
		return
	if "driver_in_car" in parent_body and not parent_body.driver_in_car:
		if particle_effect:
			particle_effect.emitting = false
		return
	if "engine_on" in parent_body and not parent_body.engine_on:
		if particle_effect:
			particle_effect.emitting = false
		if visual:
			visual.visible = false
		thruster_enabled = false
		return

	# Hold the assigned action to thrust (only when toggled on)
	var should_thrust = thruster_enabled and Input.is_action_pressed(activate_action)

	if should_thrust:
		if not was_thrusting and puff_effect:
			puff_effect.restart()

		var thrust_direction = global_transform.basis.y
		parent_body.apply_force(thrust_direction * thrust_force, global_position - parent_body.global_position)

		if particle_effect:
			particle_effect.emitting = true
	else:
		if particle_effect:
			particle_effect.emitting = false

	was_thrusting = should_thrust

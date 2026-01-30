extends Node3D

@export var thrust_force: float = 5000.0
@export var particle_effect: GPUParticles3D
@export var puff_effect: GPUParticles3D

var parent_body: VehicleBody3D
var powerup_active: bool = false
var powerup_timer: float = 0.0
var was_thrusting: bool = false

func _ready():
	# Search up the tree for VehicleBody3D
	var node = get_parent()
	while node and not node is VehicleBody3D:
		node = node.get_parent()
	parent_body = node as VehicleBody3D
	
	visible = false
	if particle_effect:
		particle_effect.emitting = false
	set_physics_process(false)
		
func activate_powerup(duration: float):
	visible = true
	powerup_active = true
	powerup_timer = duration
	set_physics_process(true)

func _physics_process(delta):
	if not parent_body:
		return
	
	# Update powerup timer
	if powerup_active:
		powerup_timer -= delta
		if powerup_timer <= 0.0:
			powerup_active = false
			visible = false
			set_physics_process(false)
	
	# Thrusters active if powerup AND space pressed
	var should_thrust = powerup_active and Input.is_action_pressed("ui_select")
	
	if should_thrust:
		# Play puff effect when starting to thrust
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

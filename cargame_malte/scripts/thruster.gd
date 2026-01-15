extends Node3D

@export var thrust_force: float = 5000.0
@export var particle_effect: GPUParticles3D

var parent_body: VehicleBody3D

func _ready():
	parent_body = get_parent() as VehicleBody3D
	if particle_effect:
		particle_effect.emitting = false

func _physics_process(_delta):
	if not parent_body:
		return
	
	if Input.is_action_pressed("ui_select"):  # SPACE key
		# Apply force in local -Y direction (downwards in thruster's local space)
		var thrust_direction = global_transform.basis.y
		parent_body.apply_force(thrust_direction * thrust_force, global_position - parent_body.global_position)
		
		if particle_effect:
			particle_effect.emitting = true
	else:
		if particle_effect:
			particle_effect.emitting = false

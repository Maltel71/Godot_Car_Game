extends Node3D

@export var sun: DirectionalLight3D
@export var environment: WorldEnvironment

@export_group("Cycle")
@export var cycle_duration: float = 10.0 ## Full day/night in seconds
@export var time_of_day: float = 0.25 ## 0.0-1.0, 0.25 = noon start

@export_group("Sun Colors")
@export var midday_color: Color = Color(1.0, 1.0, 0.95)
@export var sunset_color: Color = Color(1.0, 0.4, 0.2)

@export_group("Energy")
@export var max_energy: float = 1.0
@export var min_energy: float = 0.05

func _process(delta):
	time_of_day = fmod(time_of_day + delta / (cycle_duration * 60.0), 1.0)

	if sun:
		sun.rotation_degrees.x = time_of_day * -360.0

		# 0.0 = midnight, 0.25 = noon, 0.5 = midnight, etc.
		var sun_angle = abs(sin(time_of_day * PI))
		var horizon_factor = 1.0 - pow(sun_angle, 0.5)
		sun.light_color = midday_color.lerp(sunset_color, horizon_factor)
		sun.light_energy = lerp(min_energy, max_energy, sun_angle)

	if environment and environment.environment:
		var sun_angle = abs(sin(time_of_day * PI))
		environment.environment.background_energy_multiplier = lerp(min_energy, max_energy, sun_angle)

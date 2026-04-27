extends Node3D

@export var sun: DirectionalLight3D
@export var environment: WorldEnvironment

@export_group("Cycle")
@export var cycle_duration: float = 10.0 ## Full day/night in seconds
@export var time_of_day: float = 0.25 ## 0.0-1.0, 0.25 = noon start
@export var speed_scale_game: float = 1.0

@export_group("Sun Colors")
@export var midday_color: Color = Color(1.0, 1.0, 0.95)
@export var sunset_color: Color = Color(1.0, 0.4, 0.2)

@export_group("Energy")
@export var max_energy: float = 1.0
@export var min_energy: float = 0.05

@export_group("Fog Colors")
@export var day_fog_color: Color = Color(0.7, 0.8, 0.9)
@export var night_fog_color: Color = Color(0.05, 0.05, 0.1)

func _ready():
	Engine.time_scale = speed_scale_game

func _process(delta):
	time_of_day = fmod(time_of_day + delta / (cycle_duration * 60.0), 1.0)

	if sun:
		sun.rotation_degrees.x = time_of_day * -360.0

		var sun_height = sin(time_of_day * TAU)
		var day_factor = max(sun_height, 0.0)
		var horizon_factor = 1.0 - pow(day_factor, 0.5)

		sun.light_color = midday_color.lerp(sunset_color, horizon_factor)
		sun.light_energy = lerp(min_energy, max_energy, day_factor)

	if environment and environment.environment:
		var sun_height = sin(time_of_day * TAU)
		var day_factor = max(sun_height, 0.0)
		environment.environment.background_energy_multiplier = lerp(min_energy, max_energy, day_factor)
		environment.environment.background_energy_multiplier = lerp(min_energy, max_energy, day_factor)
		environment.environment.fog_light_color = night_fog_color.lerp(day_fog_color, day_factor)

func get_phase() -> String:
	if time_of_day < 0.2: return "Night"
	elif time_of_day < 0.3: return "Dawn"
	elif time_of_day < 0.7: return "Day"
	elif time_of_day < 0.8: return "Evening"
	else: return "Night"

func get_day_percent() -> float:
	return time_of_day * 100.0

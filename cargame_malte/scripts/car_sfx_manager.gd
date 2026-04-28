extends Node

# Export sound arrays
@export var idle_sounds: Array[AudioStream]
@export var driving_sounds: Array[AudioStream]
@export var brake_sounds: Array[AudioStream]
@export var suspension_sounds: Array[AudioStream]
@export var crash_sounds: Array[AudioStream]

@onready var audio_player: AudioStreamPlayer3D = $CarEngine

# Settings
@export var min_pitch: float = 0.8
@export var max_pitch: float = 1.5
@export var max_speed_for_pitch: float = 50.0
@export var brake_min_speed: float = 10.0
@export var suspension_threshold: float = 0.3
@export var crash_min_impulse: float = 5.0
@export var crash_pitch_variation: float = 0.1

@export var exhaust_particles_idle: GPUParticles3D

var car: VehicleBody3D
var was_braking: bool = false
var prev_suspension_states: Array = [0.0, 0.0, 0.0, 0.0]
var current_state: String = "idle"  # idle, driving, off

func _ready():
	car = get_parent()
	car.body_entered.connect(_on_collision)
	
	if idle_sounds.size() > 0:
		_play_sound(idle_sounds[0], 1.0, true)
		current_state = "idle"

func _physics_process(_delta):
	# Engine off: silence everything
	if not car.engine_on:
		if current_state != "off":
			audio_player.stop()
			current_state = "off"
		return
	
	# No driver but engine running: idle ambience
	if not car.driver_in_car:
		if current_state != "idle" and idle_sounds.size() > 0:
			_play_sound(idle_sounds[0], 1.0, true)
			current_state = "idle"
		return
	
	var speed = car.linear_velocity.length()
	var is_accelerating = Input.is_action_pressed("Gas") or Input.is_action_pressed("Reverse")
	
	# Idle/Driving logic
	if speed < 1.0 and not is_accelerating:
		if current_state != "idle":
			_play_sound(idle_sounds[0] if idle_sounds.size() > 0 else null, 1.0, true)
			current_state = "idle"
	elif is_accelerating:
		if current_state != "driving":
			_play_sound(driving_sounds[0] if driving_sounds.size() > 0 else null, 1.0, true)
			current_state = "driving"
		
		# Pitch shift based on speed
		var speed_ratio = clamp(speed / max_speed_for_pitch, 0.0, 1.0)
		audio_player.pitch_scale = lerp(min_pitch, max_pitch, speed_ratio)
	
	# Braking
	var is_braking = Input.is_action_pressed("ui_select") and speed > brake_min_speed
	if is_braking and not was_braking and brake_sounds.size() > 0:
		_play_oneshot(brake_sounds.pick_random())
	was_braking = is_braking
	
	# Suspension
	_check_suspension()

func _play_sound(sound: AudioStream, pitch: float = 1.0, loop: bool = false):
	if sound:
		audio_player.stream = sound
		audio_player.pitch_scale = pitch
		audio_player.play()

func _play_oneshot(sound: AudioStream, pitch: float = 1.0):
	# For oneshots, create temporary player to not interrupt looping sounds
	var temp_player = AudioStreamPlayer3D.new()
	add_child(temp_player)
	temp_player.bus = "sfx"
	temp_player.stream = sound
	temp_player.pitch_scale = pitch
	temp_player.play()
	temp_player.finished.connect(func(): temp_player.queue_free())

func _check_suspension():
	var wheels = [car.get_node("wheel_front_left"), car.get_node("wheel_front_right"), 
				  car.get_node("wheel_back_left"), car.get_node("wheel_back_right")]
	
	for i in wheels.size():
		if wheels[i].is_in_contact():
			var compression = wheels[i].get_skidinfo()
			if compression < suspension_threshold and prev_suspension_states[i] >= suspension_threshold:
				if suspension_sounds.size() > 0:
					_play_oneshot(suspension_sounds.pick_random())
			prev_suspension_states[i] = compression

func _on_collision(body):
	if body and crash_sounds.size() > 0:
		var impulse = car.linear_velocity.length()
		if impulse > crash_min_impulse:
			var pitch = 1.0 + randf_range(-crash_pitch_variation, crash_pitch_variation)
			_play_oneshot(crash_sounds.pick_random(), pitch)

extends Area3D

@export var pickup_sound: AudioStream
@export var hold_time: float = 2.0

@onready var audio_player = $AudioStreamPlayer3D

var car: VehicleBody3D = null
var timer: float = 0.0

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta):
	if car == null or car.HasPackage:
		return
	timer += delta
	if timer >= hold_time:
		car.HasPackage = true
		if pickup_sound:
			audio_player.stream = pickup_sound
			audio_player.play()
		timer = 0.0

func _on_body_entered(body):
	if body is VehicleBody3D:
		car = body
		timer = 0.0

func _on_body_exited(body):
	if body is VehicleBody3D:
		car = null
		timer = 0.0

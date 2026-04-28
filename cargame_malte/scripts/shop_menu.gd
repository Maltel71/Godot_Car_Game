extends CanvasLayer

@onready var exit_button: Button = $Panel/ExitButton

var previous_camera: Camera3D
var player_ref: Node = null
var player_original_mode: int = Node.PROCESS_MODE_INHERIT
var transition_time: float = 0.6
var transition_curve: Tween.TransitionType = Tween.TRANS_CUBIC

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	exit_button.pressed.connect(_on_exit_pressed)

func _on_exit_pressed():
	exit_button.disabled = true
	var current_cam := get_viewport().get_camera_3d()
	await _blend_camera(current_cam, previous_camera)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if player_ref and is_instance_valid(player_ref):
		player_ref.process_mode = player_original_mode
	queue_free()

func _blend_camera(from_cam: Camera3D, to_cam: Camera3D) -> void:
	if not from_cam or not to_cam or not is_instance_valid(to_cam) or transition_time <= 0.0:
		if to_cam and is_instance_valid(to_cam):
			to_cam.make_current()
		return
	var blend_cam := Camera3D.new()
	get_tree().current_scene.add_child(blend_cam)
	blend_cam.global_transform = from_cam.global_transform
	blend_cam.fov = from_cam.fov
	blend_cam.make_current()
	var tween := create_tween().set_trans(transition_curve).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(blend_cam, "global_transform", to_cam.global_transform, transition_time)
	tween.parallel().tween_property(blend_cam, "fov", to_cam.fov, transition_time)
	await tween.finished
	to_cam.make_current()
	blend_cam.queue_free()
	
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_exit_pressed()

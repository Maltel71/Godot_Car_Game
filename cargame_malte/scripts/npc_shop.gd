extends StaticBody3D

@export var menu_scene: PackedScene
@export var dialogue_camera: Camera3D
@export var transition_time: float = 0.6
@export var transition_curve: Tween.TransitionType = Tween.TRANS_CUBIC

@onready var interact_area: Area3D = $InteractArea

var player_in_range: Node3D = null
var menu_instance: CanvasLayer = null

func _ready():
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body is CharacterBody3D and "HasPackage" in body:
		player_in_range = body

func _on_body_exited(body):
	if body == player_in_range:
		player_in_range = null

func _unhandled_input(event):
	if event.is_action_pressed("interact") and player_in_range and not menu_instance:
		_open_shop()

func _open_shop():
	var prev_cam := get_viewport().get_camera_3d()
	await _blend_camera(prev_cam, dialogue_camera)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	menu_instance = menu_scene.instantiate()  # ← instantiate FIRST
	menu_instance.previous_camera = prev_cam
	menu_instance.transition_time = transition_time
	menu_instance.transition_curve = transition_curve
	menu_instance.player_ref = player_in_range
	menu_instance.player_original_mode = player_in_range.process_mode if player_in_range else Node.PROCESS_MODE_INHERIT  # ← THEN assign
	if player_in_range:
		player_in_range.process_mode = Node.PROCESS_MODE_DISABLED
	menu_instance.tree_exited.connect(func(): menu_instance = null)
	get_tree().current_scene.add_child(menu_instance)

func _blend_camera(from_cam: Camera3D, to_cam: Camera3D) -> void:
	if not from_cam or not to_cam or transition_time <= 0.0:
		if to_cam:
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

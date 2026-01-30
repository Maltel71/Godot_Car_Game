extends Node

var level_time: float = 0.0
var max_time: float = 60.0
var level_score: int = 0
var is_timing: bool = false

func _ready():
	pass

func _process(delta):
	if is_timing:
		level_time -= delta
		if level_time <= 0.0:
			level_time = 0.0
			times_up()

func start_timer(duration: float = 60.0):
	max_time = duration
	level_time = duration
	level_score = 0
	is_timing = true

func stop_timer():
	is_timing = false

func add_time(seconds: float):
	level_time += seconds

func add_score(points: int):
	level_score += points

func get_time() -> float:
	return level_time

func get_score() -> int:
	return level_score

func reset():
	level_time = 0.0
	level_score = 0
	is_timing = false

func times_up():
	is_timing = false
	set_process(false)
	var scene_tree = Engine.get_main_loop() as SceneTree
	if scene_tree:
		# Hide highscore UI
		var highscore_ui = scene_tree.get_first_node_in_group("highscore_ui")
		if highscore_ui:
			highscore_ui.hide()
		
		scene_tree.paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		var times_up_scene = load("res://menus/timeisup_menu.tscn")
		if times_up_scene:
			var times_up_menu = times_up_scene.instantiate()
			scene_tree.current_scene.add_child(times_up_menu)

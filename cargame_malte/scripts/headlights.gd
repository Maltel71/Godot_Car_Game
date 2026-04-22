extends SpotLight3D

func _input(event):
	if event.is_action_pressed("headlight"):
		visible = !visible

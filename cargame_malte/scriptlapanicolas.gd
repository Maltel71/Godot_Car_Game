extends SpotLight3D

func _input(lampknapp):
	if lampknapp is InputEventMouse and lampknapp.button_index == MOUSE_BUTTON_RIGHT and lampknapp.pressed:
		visible = !visible

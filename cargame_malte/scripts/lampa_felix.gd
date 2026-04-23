extends SpotLight3D

func _input(Lampknapp):
	if Lampknapp is InputEventMouse and Lampknapp.button_index == MOUSE_BUTTON_RIGHT and Lampknapp.pressed:
		visible = !visible
		

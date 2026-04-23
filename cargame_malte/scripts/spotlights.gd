extends SpotLight3D

func _input(light_button):
	if light_button is InputEventMouseButton and light_button.button_index == MOUSE_BUTTON_RIGHT and light_button.pressed:
		visible = !visible

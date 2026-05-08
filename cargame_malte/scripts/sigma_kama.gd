extends SpotLight3D

func _input(lilsis):
	if lilsis is InputEventMouseButton and lilsis.button_index == MOUSE_BUTTON_RIGHT and lilsis.pressed:
		visible = !visible
		

extends AudioStreamPlayer3D

func _input(tuuut):
	if tuuut is InputEventMouseButton and tuuut.button_index == MOUSE_BUTTON_LEFT and tuuut.pressed:
		play()

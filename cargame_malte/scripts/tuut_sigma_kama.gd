extends AudioStreamPlayer3D

func _input(TITFORTAT):
	if TITFORTAT is InputEventMouseButton and TITFORTAT.button_index == MOUSE_BUTTON_LEFT and TITFORTAT.pressed:
		play()
		

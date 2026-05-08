extends SpotLight3D

func _input(lampknapp)
if lampknapp is InputEventMouseButton and lampknapp.button_index == MOUSE_BUTTON_RIGHT and lamknapp.pressed:
visible = !visible

extends SpotLight3D

func _input(event):
	if event.is_action_pressed("headlight"):
		var car = get_parent()
		while car and not car is VehicleBody3D:
			car = car.get_parent()
		if car and "driver_in_car" in car and not car.driver_in_car:
			return
		if car and "engine_on" in car and not car.engine_on:
			return
		visible = !visible

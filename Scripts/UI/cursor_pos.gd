extends Label

func _physics_process(_delta: float) -> void:
	var pos = Map.GetCameraPosition()
	var posx = ["0","0"]
	if pos.x != 0:
		var X = float_to_4digit_string(pos.x / 10).replace("-", "")
		posx[0] = X.substr(0, 2)
		posx[1] = X.substr(1, 2)
		if (pos.x < 0):
			posx[0] = "-" + posx[0]
	var posy = ["0","0"]
	if pos.y != 0:
		var Y = float_to_4digit_string(pos.y / 10).replace("-", "")
		posy[0] = Y.substr(0, 2)
		posy[1] = Y.substr(2, 2)
		if (pos.y < 0):
			posy[0] = "-" + posy[0]
	text = "{0}°{1}' {2}°{3}'".format([posx[0], posx[1], posy[0],posy[1]])

func float_to_4digit_string(number: float) -> String:
	var int_number = abs(int(number)) # Remove sign for digit formatting
	var str_number = "%04d" % int_number # Pad with zeros
	if number < 0:
		return "-%s" % str_number # Add negative sign if needed
	else:
		return str_number

extends Label

func _physics_process(_delta: float) -> void:
	var pos = Map.GetCameraPosition()
	var posx = var_to_str(pos.x / 100).split(".")
	var posy = var_to_str(abs(pos.y) / 100).split(".")
	text = "{0}°{1}' {2}°{3}'".format([posx[0], posx[1].substr(0, 2), posy[0], posy[1].substr(0, 2)])

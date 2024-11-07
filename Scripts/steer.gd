extends Panel

signal Inp(event : InputEvent)

func _input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion):
		if ($"..".position.distance_to(event.position) <= 256):
			accept_event()
			Inp.emit(event)

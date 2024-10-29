extends Control

var MouseIn : bool

var SteeringDir : float = 0.0

var previous_mouse_angle = 0.0

signal SteeringDitChanged(NewValue : float)
signal MouseEntered()
signal MouseExited()

func _on_texture_rect_mouse_entered() -> void:
	MouseIn = true
	MouseEntered.emit()
func _on_texture_rect_mouse_exited() -> void:
	MouseIn = false
	MouseExited.emit()

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if (!MouseIn):
		return
	if (event is InputEventScreenDrag):
		var rel = event.relative / 100
		var prevsteer = SteeringDir
		if (event.position.x < position.x):
			rotation += rel.x + -rel.y
			SteeringDir += (rel.x + -rel.y) * 10
		else :
			rotation += rel.x + rel.y
			SteeringDir += (rel.x + rel.y) * 10
		if (SteeringDir != prevsteer):
			SteeringDitChanged.emit(SteeringDir)

	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		var rel = event.relative / 100
		var prevsteer = SteeringDir
		if (event.position.x < position.x):
			rotation += rel.x + -rel.y
			SteeringDir += (rel.x + -rel.y) * 40
		else :
			rotation += rel.x + rel.y
			SteeringDir += (rel.x + rel.y) * 40
		if (SteeringDir != prevsteer):
			SteeringDitChanged.emit(SteeringDir)

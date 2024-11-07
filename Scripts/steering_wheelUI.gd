extends Control

var SteeringDir : float = 0.0

var previous_mouse_angle = 0.0

signal SteeringDitChanged(NewValue : float)


func _ready() -> void:
	position = Vector2(-5 , get_viewport_rect().size.y + 8)

func UpdateSteer(RelativeRot : Vector2, EvPos : Vector2):
	var rel = clamp(RelativeRot / 100, Vector2(-0.3, -0.3), Vector2(0.3, 0.3))
	var prevsteer = SteeringDir
	if (EvPos.x < position.x):
		$TextureRect.rotation += rel.x -rel.y
		SteeringDir += (rel.x -rel.y) * 10
	else :
		$TextureRect.rotation += rel.x + rel.y
		SteeringDir += (rel.x + rel.y) * 10
	if (SteeringDir != prevsteer):
		SteeringDitChanged.emit(SteeringDir)
	if (!$AudioStreamPlayer.playing):
		$AudioStreamPlayer.playing = true

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	
	if (event is InputEventScreenDrag):
		UpdateSteer(event.relative, event.position)

	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		UpdateSteer(event.relative, event.position)


func _on_texture_rect_gui_input(event: InputEvent) -> void:

	if (event is InputEventScreenDrag):
		UpdateSteer(event.relative, event.position)

	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		UpdateSteer(event.relative, event.position)

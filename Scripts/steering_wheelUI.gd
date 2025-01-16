extends Control

class_name SteeringWheelUI

@export var PositionOnStart : bool = true

var SteeringDir : float = 0.0

var previous_mouse_angle = 0.0

signal SteeringDitChanged(NewValue : float)
signal SteeringOffseted(Offset : float)

var DistanceTraveled = 0

func _ready() -> void:
	set_physics_process(false)
	if (PositionOnStart):
		position = Vector2(-5 , get_viewport_rect().size.y + 8)

func UpdateSteer(RelativeRot : Vector2, EvPos : Vector2):
	var rel = clamp(RelativeRot / 100, Vector2(-0.3, -0.3), Vector2(0.3, 0.3))
	#var prevsteer = SteeringDir
	set_physics_process(true)
	if (EvPos.x < position.x):
		#$TextureRect.rotation += (rel.x - rel.y) /20
		SteeringDir += (rel.x -rel.y) * 2
	else :
		#$TextureRect.rotation += rel.x + rel.y /20
		SteeringDir += (rel.x + rel.y) * 2

func ForceSteer(st : float) -> void:
	$TextureRect.rotation = rad_to_deg(st)
	
func _physics_process(_delta: float) -> void:
	$TextureRect.rotation += SteeringDir
	DistanceTraveled += abs(SteeringDir)
	SteeringDir = lerp(SteeringDir, 0.0, 0.2)
	SteeringOffseted.emit(SteeringDir)
	SteeringDitChanged.emit($TextureRect.rotation)
	if (abs(SteeringDir) < 0.001):
		set_physics_process(false)
	if (DistanceTraveled > 1):
		DistanceTraveled = 0
		$AudioStreamPlayer.play()
		Input.vibrate_handheld(30)
	#if (!$AudioStreamPlayer.playing):
		
	
	#ass
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

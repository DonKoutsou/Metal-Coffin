extends Control

class_name Nob

@export var Steps = 10
var AngleStep = 0
var CurrentStep = 1
var SteeringDir : float = 0.0

var previous_mouse_angle = 0.0

var accumulatedrel : float

signal StepChanged(NewStep : int)

var DistanceTraveled = 0


func _ready() -> void:
	AngleStep = deg_to_rad(360) / Steps
	
	set_physics_process(false)

func UpdateSteer(RelativeRot : Vector2, EvPos : Vector2):
	var rel = clamp(RelativeRot / 50, Vector2(-0.3, -0.3), Vector2(0.3, 0.3))
	#var prevsteer = SteeringDir
	set_physics_process(true)
	var force : float = 0
	if (EvPos.x < 30):
		#$TextureRect.rotation += (rel.x - rel.y) /20
		force -= rel.y
	else :
		#$TextureRect.rotation += rel.x + rel.y /20
		force += rel.y
	if (EvPos.y < 30):
		#$TextureRect.rotation += (rel.x - rel.y) /20
		force += rel.x
	else :
		#$TextureRect.rotation += rel.x + rel.y /20
		force -= rel.x
		
	SteeringDir += force
func ForceSteer(st : float) -> void:
	$TextureRect.rotation = rad_to_deg(st)

func CopyShipSteer(Ship : MapShip) -> void:
	$TextureRect.rotation = Ship.GetSteer()

func _physics_process(_delta: float) -> void:
	DistanceTraveled += SteeringDir
	
	if (abs(SteeringDir) < 0.001):
		set_physics_process(false)
	if (abs(DistanceTraveled) > 3):
		DistanceTraveled = 0
		if (SteeringDir > 0):
			CurrentStep += 1
		else:
			CurrentStep -= 1
		if (CurrentStep == 11):
			CurrentStep = 1
		else: if (CurrentStep == 0):
			CurrentStep = 10
		print(CurrentStep)
		StepChanged.emit(CurrentStep)
		SteeringDir = 0
		$TextureRect.rotation = CurrentStep * AngleStep
		$AudioStreamPlayer.play()
		Input.vibrate_handheld(100)
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
	
	if (event.is_action_released("Click")):
		SteeringDir = 0

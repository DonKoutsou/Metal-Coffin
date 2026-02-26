extends Control

class_name SteeringWheelUI

@export var PositionOnStart : bool = true

var SteeringDir : float = 0.0

var previous_mouse_angle = 0.0

signal SteeringDitChanged(NewValue : float)
signal SteeringOffseted(Offset : float)

var DistanceTraveled = 0

var MoveTw : Tween

var CurrentSteerRot : float

func Toggle(t : bool) -> void:
	if (!t):
		MoveTw = create_tween()
		MoveTw.set_ease(Tween.EASE_IN)
		MoveTw.set_trans(Tween.TRANS_BACK)
		MoveTw.tween_property(self, "position", Vector2(-size.x, position.y), 0.5)
	else:
		MoveTw = create_tween()
		MoveTw.set_ease(Tween.EASE_OUT)
		MoveTw.set_trans(Tween.TRANS_BACK)
		MoveTw.tween_property(self, "position", Vector2(-size.x / 2, position.y), 0.5)

func _ready() -> void:
	set_physics_process(false)
	#if (PositionOnStart):
		#position = Vector2(-5 , get_viewport_rect().size.y + 8)

func UpdateSteer(RelativeRot : Vector2, EvPos : Vector2):
	var rel = clamp(RelativeRot / 10, Vector2(-0.3, -0.3), Vector2(0.3, 0.3))
	#var prevsteer = SteeringDir
	set_physics_process(true)
	if (EvPos.x < position.x):
		#$TextureRect.rotation += (rel.x - rel.y) /20
		SteeringDir += rel.x -rel.y
	else :
		#$TextureRect.rotation += rel.x + rel.y /20
		SteeringDir += rel.x + rel.y

func UpdateSteerFloat(Dir : float) -> void:
	set_physics_process(true)
	SteeringDir += Dir * 10


func ForceSteer(st : float) -> void:
	#var rotamm = st - CurrentSteerRot
	if (Syncing):
		return
	CurrentSteerRot = st
	SteeringDir = 0
	# set_physics_process(false)
	#SteerRotated(rotamm)
	
var forceTw : Tween
var Syncing : bool = false
func SyncSteer(st : float) -> void:
	CurrentSteerRot = st
	SteeringDir = 0
	#set_physics_process(false)
	#Syncing = true
	#forceTw = create_tween()
	##print("Forcing steer of value {0}".format([st]))
	#forceTw.set_ease(Tween.EASE_OUT)
	#forceTw.set_trans(Tween.TRANS_QUINT)
	#forceTw.tween_method(RotateTexture, CurrentSteerRot, st, 1)
	#forceTw.finished.connect(set.bind("Syncing", false))
	#$TextureRect.rotation = rad_to_deg(st)

func RotateTexture(NewRot : float) -> void:
	var rotamm = NewRot - $TextureRect.rotation
	SteerRotated(rotamm)
	CurrentSteerRot = NewRot

func SteerRotated(Amm : float) -> void:
	DistanceTraveled += abs(Amm)
	if (DistanceTraveled > 0.2):
		DistanceTraveled = 0
		$AudioStreamPlayer.play()
		Input.vibrate_handheld(30)

func CopyShipSteer(Ship : MapShip) -> void:
	$TextureRect.rotation = Ship.rotation

func _process(delta: float) -> void:
	var newrot = lerp($TextureRect.rotation, CurrentSteerRot * 10, delta * 4)
	var rotamm = newrot - $TextureRect.rotation
	$TextureRect.rotation = newrot
	SteerRotated(rotamm)

func _physics_process(delta: float) -> void:
	SteeringDir = lerp(SteeringDir, 0.0, 0.2)
	#$TextureRect.rotation = wrap($TextureRect.rotation + SteeringDir / 5, -PI, PI)
	
	SteeringOffseted.emit(SteeringDir)
	SteeringDitChanged.emit(SteeringDir)
	if (abs(SteeringDir) < 0.001):
		set_physics_process(false)
	
	
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

	else: if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		UpdateSteer(event.relative, event.position)

	var axis = Input.get_axis("ZoomIn", "ZoomOut")
	if (axis != 0):
		UpdateSteerFloat(axis * 0.4)

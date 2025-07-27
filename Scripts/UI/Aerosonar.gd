extends Control

class_name  AeroSonar

@export var ControllerEventH : ShipControllerEventHandler
@export var OffsetAmmount : float
@export var LineContainer : AeroSonarLine
@export var SonalVisual : TextureRect

var Offset = 0.0
var CurrentAngle : float
var Controller : PlayerDrivenShip
var Working : bool = false

func _ready() -> void:
	#Controller = ControllerEventH.CurrentControlled
	ControllerEventH.OnControlledShipChanged.connect(ControlledShipUpdated)
	set_physics_process(false)
	SonalVisual.hide()

func ControlledShipUpdated(NewController : PlayerDrivenShip) -> void:
	if (Controller != null):
		Controller.ToggleSonarVisual(false)
		#Implement deactivation of sonar collider
	
	Controller = NewController
	Controller.ToggleSonarVisual(Working)


func SonarRotationChanged(NewVal: float) -> void:
	CurrentAngle = wrap(CurrentAngle + (NewVal / 100), -PI, PI)
	Controller.SetSonarDirection(CurrentAngle)

func _physics_process(delta: float) -> void:
	Controller.SetSonarDirection(CurrentAngle)
	Offset = wrap(Offset + (delta * 10), 0, 2)
	UpdateContacts()
	#queue_redraw()

func UpdateContacts() -> void:
	var ContactList : Dictionary[int, float]
	for g in Controller.SonarTargets:
		if (g == Controller):
			continue
		var dir = Controller.global_position.direction_to(g.global_position).angle()
		var dif = Helper.angle_difference_radians(dir, CurrentAngle)
		if (abs(dif) > PI / 4):
			continue
		var RoundedAngle = roundi(rad_to_deg(dif) + 25)
		var Dist = Controller.global_position.distance_squared_to(g.global_position) / 1000000
		var Thrust = g.GetShipThrust() / 30
		if (ContactList.has(RoundedAngle)):
			ContactList[RoundedAngle] += (1 - Dist) * Thrust
		else:
			ContactList[RoundedAngle] = (1 - Dist) * Thrust
			
	LineContainer.Update(ContactList, Vector2.RIGHT.rotated((-PI / 2) + CurrentAngle).angle() + PI)


func _on_close_pressed() -> void:
	var tw = create_tween()
	tw.tween_property(SonalVisual, "position", Vector2(-SonalVisual.size.x, SonalVisual.position.y), 0.5)
	tw.finished.connect(SonalVisual.hide)
	set_physics_process(false)
	Controller.ToggleSonarVisual(false)
	Working = false

func OnRadioClicked() -> void:
	var tw = create_tween()
	tw.tween_property(SonalVisual, "position", Vector2(-SonalVisual.size.x / 3, SonalVisual.position.y), 0.5)
	SonalVisual.show()
	set_physics_process(true)
	Controller.ToggleSonarVisual(true)
	Working = true

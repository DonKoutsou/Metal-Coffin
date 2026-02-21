#Aerosonar works by finding ships and registering them in the sonar based on their
#heat signature. Heat signature has to do with their thrust power. So bigger ships
#can be found from further
extends Control

class_name  AeroSonar

@export var ControllerEventH : ShipControllerEventHandler
@export var DroneDockEventH : DroneDockEventHandler
@export var OffsetAmmount : float
@export var LineContainer : AeroSonarLine
@export var SonalVisual : TextureRect
@export var GainLabel : Label
@export var Spkr : RadioSpeaker

var Offset = 0.0
var CurrentAngle : float
var CurrentOffset : float = 1
var Controller : PlayerDrivenShip
var Working : bool = false
var Enabled : bool = false
var Vol : float

func _ready() -> void:
	DroneDockEventH.DroneDocked.connect(DroneAdded)
	DroneDockEventH.DroneUndocked.connect(DroneRemoved)
	#connect to be notified that the controlled ship has changed
	ControllerEventH.OnControlledShipChanged.connect(ControlledShipUpdated)
	Controller = ControllerEventH.CurrentControlled
	#connect to the found signal. when a signal is visible in the sonar we call a function
	LineContainer.Found.connect(SignalFound)
	#turn everything off
	set_physics_process(false)
	LineContainer.visible = false
	GainLabel.visible = false

func DroneAdded(Dr : Drone, Target : MapShip) -> void:
	if (Target == Controller):
		Working = FleetHasAerosonar()
		Controller.ToggleSonarVisual(Enabled)
		if (!Working):
			LineContainer.OffsetAmmount = 0
		else:
			LineContainer.OffsetAmmount = CurrentOffset

func DroneRemoved(Dr : Drone, Target : MapShip) -> void:
	if (Target == Controller):
		Working = FleetHasAerosonar()
		Controller.ToggleSonarVisual(Enabled)
		if (!Working):
			LineContainer.OffsetAmmount = 0
		else:
			LineContainer.OffsetAmmount = CurrentOffset

func SignalFound(Str : float) -> void:
	Spkr.PlaySound(RadioSpeaker.RadioSound.BEEP, Str - 35)

func ControlledShipUpdated(NewController : PlayerDrivenShip) -> void:
	if (Controller != null):
		Controller.ToggleSonarVisual(false)
		#Implement deactivation of sonar collider
	
	Controller = NewController
	
	Working = FleetHasAerosonar()
	Controller.ToggleSonarVisual(Enabled)

func FleetHasAerosonar() -> bool:
	if (Controller.Cpt.GetStatFinalValue(STAT_CONST.STATS.AEROSONAR_RANGE) > 0):
		return true
	for g : Captain in Controller.GetDroneDock().GetCaptains():
		var CaptainSonarRange = g.GetStatFinalValue(STAT_CONST.STATS.AEROSONAR_RANGE)
		if (CaptainSonarRange > 0):
			return true
	return false

func GetCurrentFleetAerosonarRange() -> float:
	var BiggestAeroSonarInFleer : float = Controller.Cpt.GetStatFinalValue(STAT_CONST.STATS.AEROSONAR_RANGE)
	for g : Captain in Controller.GetDroneDock().GetCaptains():
		var CaptainSonarRange = g.GetStatFinalValue(STAT_CONST.STATS.AEROSONAR_RANGE)
		if (CaptainSonarRange > BiggestAeroSonarInFleer):
			BiggestAeroSonarInFleer = CaptainSonarRange
	return BiggestAeroSonarInFleer

func SonarRotationChanged(NewVal: float) -> void:
	CurrentAngle = wrap(CurrentAngle + (NewVal / 20), -PI, PI)
	Controller.SetSonarDirection(CurrentAngle)

func _physics_process(delta: float) -> void:
	Controller.SetSonarDirection(CurrentAngle)
	Offset = wrap(Offset + (delta * 10), 0, 2)
	UpdateContacts()
	Spkr.PlaySound(RadioSpeaker.RadioSound.STATIC, Vol - 15)
	#queue_redraw()

func IsPartOfFleet(SonarTarget : Node2D) -> bool:
	return SonarTarget == Controller or SonarTarget in Controller.GetDroneDock().GetDockedShips()

func UpdateContacts() -> void:
	#we itterate through the stored targets we currently have to find the ones we actually seeing
	#based on their heat signature
	var ContactList : Dictionary[int, float]
	for g in Controller.GetSonarTargets():
		#if ship is controlled ship we continue
		if (g is PlayerDrivenShip and IsPartOfFleet(g)):
			continue
		
		var LineOfSight = TopographyMap.Instance.WithinLineOfSight(Controller.global_position, Controller.Altitude, g.global_position, g.Altitude)
		if (!LineOfSight):
			continue
		#find the angle at wich the ship is at from us
		var dir = Controller.global_position.direction_to(g.global_position).angle()
		#check if its within the current angle of the sonar
		var dif = Helper.angle_difference_radians(dir, CurrentAngle)
		if (abs(dif) > PI / 4):
			continue
			
		#get ship thrust value
		var Thrust : float
		if (g is MapShip):
			Thrust = g.GetShipThrust() / 30
		else : if (g is Missile):
			Thrust = g.Speed / 500
			
		#if current angle exis we add the thrust to it if not we create the new entry
		var Dist = Controller.global_position.distance_squared_to(g.global_position) / 1000000
		var RoundedAngle = roundi(rad_to_deg(dif) + 25)
		if (ContactList.has(RoundedAngle)):
			ContactList[RoundedAngle] += (1 - Dist) * Thrust
		else:
			ContactList[RoundedAngle] = (1 - Dist) * Thrust
			
	LineContainer.Update(ContactList, Vector2.RIGHT.rotated((-PI / 2) + CurrentAngle).angle() + PI)

func Toggle(t : bool) -> void:
	#var tw = create_tween()
	if (!t):
		_on_close_pressed()
	else:
		OnRadioClicked()

#var tw : Tween
func _on_close_pressed() -> void:
	if (!FleetHasAerosonar):
		PopUpManager.GetInstance().DoFadeNotif("Ship missing sonar")
		return
	ToggleSonar(!Working)

func _on_close_toggled(toggled_on: bool) -> void:
	ToggleSonar(toggled_on)
	pass # Replace with function body.

func ToggleSonar(t : bool) -> void:
	LineContainer.visible = t
	GainLabel.visible = t
	set_physics_process(t)
	Enabled = t
	if (t):
		Working = FleetHasAerosonar()
		Controller.ToggleSonarVisual(Working)
		if (!Working):
			PopUpManager.GetInstance().DoFadeNotif("Ship missing sonar")
			LineContainer.OffsetAmmount = 0
		else:
			LineContainer.OffsetAmmount = CurrentOffset
	else:
		Controller.ToggleSonarVisual(false)


func OnRadioClicked() -> void:
	return
	#if (is_instance_valid(tw)):
		#tw.kill()
	#if (Controller.Cpt.GetStatFinalValue(STAT_CONST.STATS.AEROSONAR_RANGE) == 0):
		#return
	#tw = create_tween()
	#tw.tween_property(SonalVisual, "position", Vector2(-SonalVisual.size.x / 3, SonalVisual.position.y), 0.5)
	#tw.finished.connect(SonalVisual.show)
	#SonalVisual.show()
	#set_physics_process(true)
	#Controller.ToggleSonarVisual(true)
	#Working = true


func _on_gein_control_range_changed(NewVal: float) -> void:
	var newoffset = clamp(CurrentOffset + (-NewVal / 2), 1 ,25)
	Vol = newoffset
	CurrentOffset = newoffset
	GainLabel.text = "Gain:{0}".format([snapped(newoffset, 0.1)]).replace(".0", "")
	if (!Working):
		return
	LineContainer.OffsetAmmount = newoffset
	

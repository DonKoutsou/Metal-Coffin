#Aerosonar works by finding ships and registering them in the sonar based on their
#heat signature. Heat signature has to do with their thrust power. So bigger ships
#can be found from further
extends Control

class_name  AeroSonar

@export var ControllerEventH : ShipControllerEventHandler
@export var OffsetAmmount : float
@export var LineContainer : AeroSonarLine
@export var SonalVisual : TextureRect
@export var GainLabel : Label
@export var Spkr : RadioSpeaker

var Offset = 0.0
var CurrentAngle : float
var Controller : PlayerDrivenShip
var Working : bool = false
var Vol : float

func _ready() -> void:
	#connect to be notified that the controlled ship has changed
	ControllerEventH.OnControlledShipChanged.connect(ControlledShipUpdated)
	Controller = ControllerEventH.CurrentControlled
	#connect to the found signal. when a signal is visible in the sonar we call a function
	LineContainer.Found.connect(SignalFound)
	#turn everything off
	set_physics_process(false)
	LineContainer.visible = false
	GainLabel.visible = false


func SignalFound(Str : float) -> void:
	Spkr.PlaySound(RadioSpeaker.RadioSound.BEEP, Str - 35)

func ControlledShipUpdated(NewController : PlayerDrivenShip) -> void:
	if (Controller != null):
		Controller.ToggleSonarVisual(false)
		#Implement deactivation of sonar collider
	
	Controller = NewController
	if (Controller.Cpt.GetStatFinalValue(STAT_CONST.STATS.AEROSONAR_RANGE) == 0 and Working):
		PopUpManager.GetInstance().DoFadeNotif("Unable to locate sonar on ship.\nDissabling interface...")
		ToggleSonar(false)
	Controller.ToggleSonarVisual(Working)


func SonarRotationChanged(NewVal: float) -> void:
	CurrentAngle = wrap(CurrentAngle + (NewVal / 20), -PI, PI)
	Controller.SetSonarDirection(CurrentAngle)

func _physics_process(delta: float) -> void:
	Controller.SetSonarDirection(CurrentAngle)
	Offset = wrap(Offset + (delta * 10), 0, 2)
	UpdateContacts()
	Spkr.PlaySound(RadioSpeaker.RadioSound.STATIC, Vol - 15)
	#queue_redraw()

func UpdateContacts() -> void:
	#we itterate through the stored targets we currently have to find the ones we actually seeing
	#based on their heat signature
	var ContactList : Dictionary[int, float]
	for g in Controller.SonarTargets:
		#if ship is controlled ship we continue
		if (g == Controller):
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
	if (Controller.Cpt.GetStatFinalValue(STAT_CONST.STATS.AEROSONAR_RANGE) == 0):
		PopUpManager.GetInstance().DoFadeNotif("Ship missing sonar")
		return
	ToggleSonar(!Working)

func ToggleSonar(t : bool) -> void:
	LineContainer.visible = t
	GainLabel.visible = t
	set_physics_process(t)
	Controller.ToggleSonarVisual(t)
	Working = t


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
	var newoffset = clamp(LineContainer.OffsetAmmount + (-NewVal / 2), 1 ,25)
	Vol = newoffset
	LineContainer.OffsetAmmount = newoffset
	GainLabel.text = "Gain:{0}".format([snapped(newoffset, 0.1)]).replace(".0", "")

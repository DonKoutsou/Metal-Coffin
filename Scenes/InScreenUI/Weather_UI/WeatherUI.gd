extends Control

class_name WeatherUI

@export var VizText : Label
@export var WindText : Label
@export var WindDirArrow : Label
@export var DangerLabel : Label
@export var ShipControllerEventH : ShipControllerEventHandler

var CurrentShip : PlayerDrivenShip
var lastWindSpeed : float
var lastWindAngle : float
var lastGlobalWindSpeed : float

func _ready() -> void:
	ShipControllerEventH.OnControlledShipChanged.connect(ControlledShipChanged)
	set_physics_process(false)

func ControlledShipChanged(NewShip : PlayerDrivenShip) -> void:
	CurrentShip = NewShip
	set_physics_process(true)

var d = 0.2
func _physics_process(delta: float) -> void:
	var WindAngle = WeatherManage.WindDirection.angle()
	
	var ws = roundi(TopographyMap.GetWindAtPos(CurrentShip.global_position, CurrentShip.Altitude))
	#var ws = roundi(WeatherManage.WindSpeed * CurrentShip.WindEffect)
	lastWindAngle = move_toward(lastWindAngle, WindAngle, delta * 20)
	lastWindSpeed = move_toward(lastWindSpeed, ws, delta * 20)
	lastGlobalWindSpeed = move_toward(lastGlobalWindSpeed, WeatherManage.WindSpeed, delta * 20)
	
	var wd = Helper.AngleToDirectionShort(lastWindAngle)
	WindText.text = "Global Wind : {1}km/h Local Wind  : {2}km/h".format([wd, roundi(lastGlobalWindSpeed) ,roundi(lastWindSpeed)])
	WindDirArrow.rotation = WindAngle
	$HBoxContainer/HBoxContainer/Control/Label2.text = wd
	
	var vis = ShipContoller.ControlledShipVisibilityPenaltyValue
	VizText.text = "Visibility = {0}".format([GetTextForVis(vis), snapped(vis, 0.01)])
	
	if (ShipContoller.ControlledShipStormValue < 0.9):
		DangerLabel.visible = false
	else:
		d -= delta
		if (d <= 0):
			d = 0.2
			DangerLabel.visible = !DangerLabel.visible
	
func GetTextForVis(Vis : float) -> String:
	if (Vis > 0.9):
		return "Clear"
	else: if (Vis > 0.7):
		return "Dim"
	else:
		return "Low"

func _on_button_pressed() -> void:
	ShipCamera.GetInstance().ToggleWeatherMan()

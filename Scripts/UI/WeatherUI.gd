extends Control

class_name WeatherUI

@export var ShipControllerEventH : ShipControllerEventHandler
@export var VizText : Label
@export var DangerLabel : Label

var CurrentShip : PlayerDrivenShip

func _ready() -> void:
	ShipControllerEventH.connect("OnControlledShipChanged", ControlledShipChanged)
	CurrentShip = ShipControllerEventH.CurrentControlled

func ControlledShipChanged(NewShip : PlayerDrivenShip) -> void:
	CurrentShip = NewShip

var d = 0.2
func _physics_process(delta: float) -> void:
	if (CurrentShip == null):
		return
		
	var vis = WeatherManage.GetVisibilityInPosition(CurrentShip.global_position)
	VizText.text = "Visibility : {0}".format([GetTextForVis(vis), snapped(vis, 0.01)])
	
	if (vis > 0.6):
		DangerLabel.visible = false
	else:
		d -= delta
		if (d <= 0):
			d = 0.2
			DangerLabel.visible = !DangerLabel.visible
	
func GetTextForVis(Vis : float) -> String:
	if (Vis > 0.9):
		return "Clear"
	if (Vis > 0.7):
		return "Dim"
	return "Low"

func _on_button_pressed() -> void:
	ShipCamera.GetInstance().ToggleWeatherMan()

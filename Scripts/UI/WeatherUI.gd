extends Control

class_name WeatherUI

@export var VizText : Label
@export var WindText : Label
@export var DangerLabel : Label

var d = 0.2
func _physics_process(delta: float) -> void:
	var wd = Helper.AngleToDirectionShort(WeatherManage.WindDirection.angle())
	WindText.text = "Wind Dir = {0}".format([wd])
	
	var vis = WeatherManage.GetVisibilityInPosition(ShipContoller.ControlledShipPosition)
	VizText.text = "Visibility = {0}".format([GetTextForVis(vis), snapped(vis, 0.01)])
	
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
	else: if (Vis > 0.7):
		return "Dim"
	else:
		return "Low"

func _on_button_pressed() -> void:
	ShipCamera.GetInstance().ToggleWeatherMan()

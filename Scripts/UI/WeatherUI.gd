extends Control

class_name WeatherUI

@export var VizText : Label
@export var WindText : Label
@export var WindDirArrow : Label
@export var DangerLabel : Label

var d = 0.2
func _physics_process(delta: float) -> void:
	var WindAngle = WeatherManage.WindDirection.angle()
	var wd = Helper.AngleToDirectionShort(WindAngle)
	var ws = roundi(WeatherManage.WindSpeed)
	WindText.text = "Wind Dir = {0}\n SPD : {1}km/h".format([wd, ws])
	WindDirArrow.rotation = WindAngle
	var vis = ShipContoller.ControlledShipVisibilityValue
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

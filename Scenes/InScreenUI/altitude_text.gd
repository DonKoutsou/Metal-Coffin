extends Label

class_name AltitudeText

func _physics_process(delta: float) -> void:
	var pos = ShipCamera.Instance.get_screen_center_position()
	var alt = TopographyMap.Instance.GetAltitudeAtGlobalPosition(pos)
	var Storm = WeatherManage.Instance.StormValueInPosition(pos)
	#var turbelance = TopographyMap.Instance.GetTurbelance(pos)
	#var WindFeel = WeatherManage.WindSpeed * TopographyMap.Instance.GetWindProtection(pos, alt)
	text = "{0}KM\n{1}".format([snappedf(alt, 0.1) / 1000, Storm])

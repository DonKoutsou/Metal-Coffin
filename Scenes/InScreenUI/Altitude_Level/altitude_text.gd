extends Label

class_name AltitudeText

func _physics_process(_delta: float) -> void:
	if (is_visible_in_tree()):
		var pos = ShipCamera.Instance.get_global_mouse_position()
		get_parent().global_position = get_global_mouse_position()
		var alt = TopographyMap.GetAltitudeAtGlobalPosition(pos)
		#var Storm = WeatherManage.Instance.StormValueInPosition(pos)
		#var turbelance = TopographyMap.Instance.GetTurbelance(pos)
		#var WindFeel = WeatherManage.WindSpeed * TopographyMap.Instance.GetWindProtection(pos, alt)
		#if (alt < 0):
			#print(alt)
		text = "{0}KM".format([snappedf(alt / 1000, 0.1)])

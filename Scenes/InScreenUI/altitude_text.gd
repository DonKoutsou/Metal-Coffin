extends Label

class_name AltitudeText

func _physics_process(delta: float) -> void:
	text = "{0}".format([snappedf(TopographyMap.Instance.GetAltitudeAtGlobalPosition(ShipCamera.Instance.get_screen_center_position()), 0.1)])

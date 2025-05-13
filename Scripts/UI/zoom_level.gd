extends Label

class_name ZoomLevel

func _ready() -> void:
	var map = Map.GetInstance()
	if (!is_instance_valid(map)):
		return
	map.GetCamera().connect("ZoomChanged", ZoomUpdated)

func ZoomUpdated(NewZoom : float) -> void:
	text = "Zoom Level : {0}X".format([snappedf(NewZoom, 0.01)])

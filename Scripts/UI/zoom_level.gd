extends Label

class_name ZoomLevel

func _ready() -> void:
	ShipCamera.GetInstance().connect("ZoomChanged", ZoomUpdated)

func ZoomUpdated(NewZoom : float) -> void:
	text = "Zoom Level : {0}X".format([snappedf(NewZoom, 0.01)])

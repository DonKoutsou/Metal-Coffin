extends PanelContainer

class_name ZoomLvevel

var MaxZoom : float
var MinZoom : float

func _ready() -> void:
	var map = Map.GetInstance()
	if (!is_instance_valid(map)):
		return
	var cam = map.GetCamera()
	MaxZoom = cam.MaxZoom
	MinZoom = cam.MinZoom
	cam.connect("ZoomChanged", ZoomUpdated)
	$HBoxContainer/VBoxContainer/ProgressBar.max_value = MaxZoom - MinZoom
	$HBoxContainer/VBoxContainer/ProgressBar.value = cam.zoom.x - MinZoom

func ZoomUpdated(NewZoom : float) -> void:
	$HBoxContainer/VBoxContainer/Label.text = var_to_str(snappedf(NewZoom + 1, 0.1)) + "X"
	$HBoxContainer/VBoxContainer/ProgressBar.value = NewZoom - MinZoom

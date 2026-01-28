extends Control

class_name ZoomLvevel

@export var Steps : int = 20
@export var Text : Label
@export var MaxStep : float = 10.0

var MaxZoom : float
var MinZoom : float

var CurrentZoom : float = 0.5
var Working : bool = true

func _ready() -> void:
	MaxZoom = ShipCamera.MaxZoom
	MinZoom = ShipCamera.MinZoom
	#$HBoxContainer/VBoxContainer/ProgressBar.max_value = MaxZoom - MinZoom
	#$HBoxContainer/VBoxContainer/ProgressBar.value = cam.zoom.x - MinZoom

func UpdateCameraZoom(NewZoom : float) -> void:
	if (!Working):
		return
	CurrentZoom = snapped(NewZoom, 0.01)
	
	#print("New zoom = {0}".format([CurrentZoom]))
	queue_redraw()
	#$HBoxContainer/VBoxContainer/ProgressBar.value = NewZoom - MinZoom
	#queue_redraw()

func Toggle(t) -> void:
	Working = t
	visible = t

@export var Off : float = 1
func _draw() -> void:
	var ContainerSize = size.y
	
	var Z = Helper.normalize_value(CurrentZoom, MinZoom, MaxZoom)
	
	var T = "{0}X".format([snappedf(Z * MaxStep, 0.1)])
	
	Text.text = T.replace(".0", "")
	
	var StepSize = (ContainerSize) / Steps
	
	var CurrentStep = Z * Steps
	
	var MidPoint = (ContainerSize / 2.0)
	
	var CurrentStepPosition = StepSize * CurrentStep
	
	var Offset = CurrentStepPosition - MidPoint
	
	var F = load("res://Fonts/DOTMATRI.TTF") as Font
	
	var MidLinePos = MidPoint + Offset
	
	var ZoomPerStep = MaxStep / Steps
	var MidZoom = snapped(ZoomPerStep * (Steps / 2.0), 0.10)
	
	if (MidLinePos > 0 and MidLinePos < ContainerSize):
		draw_line(Vector2(15 + Off, MidLinePos) , Vector2(25 + Off, MidLinePos), Color(100, 0.764, 0.081), 2)
		draw_string(get_theme_default_font(), Vector2(26 + Off, MidLinePos + 3), var_to_str(MidZoom),HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(100, 0.764, 0.081))
		
	for g in range(1, Steps + 1):
		var UpOffset = MidPoint + Offset + (StepSize * g)
		if (UpOffset > 0 and UpOffset < ContainerSize):
			var StepZoom = snapped(MidZoom - (ZoomPerStep * g), 0.1)
			var ZoomStr = "{0}".format([StepZoom])
			if (ZoomStr.contains(".0")):
				draw_line(Vector2(15 + Off, UpOffset), Vector2(25 + Off, UpOffset), Color(100, 0.764, 0.081), 3)
				draw_string(get_theme_default_font(), Vector2(26 + Off, UpOffset + 6), ZoomStr.replace(".0", ""),HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color(100, 0.764, 0.081))
			else:
				draw_line(Vector2(15 + Off, UpOffset), Vector2(25 + Off, UpOffset), Color(100, 0.764, 0.081), 1)
				draw_string(get_theme_default_font(), Vector2(26 + Off, UpOffset + 3), ZoomStr,HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(100, 0.764, 0.081))
		var DownOffset = MidPoint + Offset + (StepSize * -g)
		if (DownOffset > 0 and DownOffset < ContainerSize):
			var StepZoom = snapped(MidZoom + (ZoomPerStep * g), 0.1)
			var ZoomStr = "{0}".format([StepZoom])
			if (ZoomStr.contains(".0")):
				draw_line(Vector2(15 + Off, DownOffset), Vector2(25 + Off, DownOffset), Color(100, 0.764, 0.081), 3)
				draw_string(get_theme_default_font(), Vector2(26 + Off, DownOffset + 6), ZoomStr.replace(".0", ""),HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color(100, 0.764, 0.081))
			else:
				draw_line(Vector2(15 + Off, DownOffset), Vector2(25 + Off, DownOffset), Color(100, 0.764, 0.081), 1)
				draw_string(get_theme_default_font(), Vector2(26 + Off, DownOffset + 3), ZoomStr,HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(100, 0.764, 0.081))

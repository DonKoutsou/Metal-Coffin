extends Control

class_name ZoomLvevel

@export var Steps : int = 20
@export var Text : Label

var MaxZoom : float
var MinZoom : float

var CurrentZoom : float = 0.5
var Working : bool = true

func _ready() -> void:
	var map = Map.GetInstance()
	if (!is_instance_valid(map)):
		return
	var cam = map.GetCamera()
	MaxZoom = cam.MaxZoom
	MinZoom = cam.MinZoom
	cam.connect("ZoomChanged", ZoomUpdated)
	#$HBoxContainer/VBoxContainer/ProgressBar.max_value = MaxZoom - MinZoom
	#$HBoxContainer/VBoxContainer/ProgressBar.value = cam.zoom.x - MinZoom

func ZoomUpdated(NewZoom : float) -> void:
	if (!Working):
		return
	CurrentZoom = NewZoom - MinZoom
	Text.text = var_to_str(snappedf(NewZoom - MinZoom, 0.1)) + "X"
	queue_redraw()
	#$HBoxContainer/VBoxContainer/ProgressBar.value = NewZoom - MinZoom
	#queue_redraw()

func Toggle(t) -> void:
	Working = t
	visible = t

@export var Off : float = 1
func _draw() -> void:
	var ContainerSize = size.y
	
	var StepSize = (ContainerSize ) / Steps
	
	var CurrentStep =((CurrentZoom  - MinZoom * 2) / MaxZoom) * Steps
	
	var MidPoint = ContainerSize / 2
	
	var HighestPos = -2
	
	var CurrentStepPosition = HighestPos + (StepSize * CurrentStep)
	
	var Offset = CurrentStepPosition - MidPoint
	
	var F = load("res://Fonts/DOTMATRI.TTF") as Font
	
	var MidLinePos = MidPoint + Offset
	
	var ZoomPerStep = MaxZoom / Steps
	var MidZoom = snapped(ZoomPerStep * (Steps / 2) + MinZoom, 0.1)
	
	if (MidLinePos > 0 and MidLinePos < ContainerSize):
		draw_line(Vector2(15 + Off, MidLinePos) , Vector2(25 + Off, MidLinePos), Color(100, 0.764, 0.081), 2)
		draw_string(get_theme_default_font(), Vector2(26 + Off, MidLinePos + 3), var_to_str(MidZoom),HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(100, 0.764, 0.081))
		
	for g in range(1, Steps + 1):
		var UpOffset = MidPoint + Offset + (StepSize * g)
		if (UpOffset > 0 and UpOffset < ContainerSize):
			var StepZoom = snapped(MidZoom - (ZoomPerStep * g), 0.1)
			
			if (var_to_str(StepZoom).contains(".0")):
				draw_line(Vector2(15 + Off, UpOffset), Vector2(25 + Off, UpOffset), Color(100, 0.764, 0.081), 3)
				draw_string(get_theme_default_font(), Vector2(26 + Off, UpOffset + 6), var_to_str(roundi(StepZoom)),HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color(100, 0.764, 0.081))
			else:
				draw_line(Vector2(15 + Off, UpOffset), Vector2(25 + Off, UpOffset), Color(100, 0.764, 0.081), 1)
				draw_string(get_theme_default_font(), Vector2(26 + Off, UpOffset + 3), var_to_str(StepZoom),HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(100, 0.764, 0.081))
		var DownOffset = MidPoint + Offset + (StepSize * -g)
		if (DownOffset > 0 and DownOffset < ContainerSize):
			var StepZoom = snapped(MidZoom + (ZoomPerStep * g), 0.1)
			
			if (var_to_str(StepZoom).contains(".0")):
				draw_line(Vector2(15 + Off, DownOffset), Vector2(25 + Off, DownOffset), Color(100, 0.764, 0.081), 3)
				draw_string(get_theme_default_font(), Vector2(26 + Off, DownOffset + 6), var_to_str(roundi(StepZoom)),HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color(100, 0.764, 0.081))
			else:
				draw_line(Vector2(15 + Off, DownOffset), Vector2(25 + Off, DownOffset), Color(100, 0.764, 0.081), 1)
				draw_string(get_theme_default_font(), Vector2(26 + Off, DownOffset + 3), var_to_str(StepZoom),HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(100, 0.764, 0.081))

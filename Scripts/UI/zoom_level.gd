extends Control

class_name ZoomLvevel

@export var Steps : int = 20
@export var Text : Label
@export var MaxStep : float = 10.0

const NUMBER_OFFSET : int = 35
const TEXT_COLOR : Color = Color(100, 0.764, 0.081)

var CurrentZoom : float = 0.5
var Working : bool = true


func UpdateCameraZoom(NewZoom : float) -> void:
	if (Working):
		CurrentZoom = snapped(NewZoom, 0.01)
		queue_redraw()

func Toggle(t) -> void:
	Working = t
	visible = t


func _draw() -> void:
	#Size of UI element
	var ContainerSize = size.y

	#Normalised value of current zoom
	var Z = Helper.normalize_value(CurrentZoom, ShipCamera.MinZoom, ShipCamera.MaxZoom)

	#Text sting
	var T = "{0}X".format([snapped(Z * MaxStep, 0.01)])
	Text.text = T

	#Based on the size of the container we figure out how much distance each step has from each other
	var StepSize = ContainerSize / Steps
	
	#Find out which step we are currently on and its position
	var CurrentStep = Z * Steps
	var CurrentStepPosition = StepSize * CurrentStep
	
	#Find the midpoint of the container
	var MidPoint = (ContainerSize / 2.0)
	
	#Find how much the elements should be offsetted so that the current step is in the middle
	var Offset = CurrentStepPosition - MidPoint
	
	#Find the inclement at wich the zoom ammount will change
	var ZoomPerStep = MaxStep / Steps
	#Find the value of the middle step
	var MidZoom = snapped(ZoomPerStep * (Steps / 2.0), 0.10)
	
	#Start from top and calculate the steps
	for g in range(-Steps - 1, Steps + 1):
		
		#Calculate the position
		var UpOffset = MidPoint + Offset + (StepSize * g)
		
		#If position is out of screen continue
		if (UpOffset < 0 or UpOffset > ContainerSize):
			continue
			
		#Calculate the positions of the line and the text
		var LineStartPos = Vector2(15 + NUMBER_OFFSET, UpOffset)
		var LineEndPos = Vector2(25 + NUMBER_OFFSET, UpOffset)
		var TextPos = Vector2(26 + NUMBER_OFFSET, UpOffset)
		
		#Figue out the  number and turn it into a string
		var StepZoom = snapped(MidZoom - (ZoomPerStep * g), 0.1)
		var ZoomStr = "{0}".format([StepZoom])
		
		#Whole numbers with no decimals are shown as bigger
		if (ZoomStr.contains(".0")):
			
			TextPos += Vector2(0,6)
			draw_string(get_theme_default_font(), TextPos, ZoomStr.replace(".0", ""),HORIZONTAL_ALIGNMENT_CENTER, -1, 20, TEXT_COLOR)
			
			draw_line(LineStartPos, LineEndPos, TEXT_COLOR, 3)
			
		else:
			
			TextPos += Vector2(0,3)
			draw_string(get_theme_default_font(), TextPos, ZoomStr,HORIZONTAL_ALIGNMENT_CENTER, -1, 12, TEXT_COLOR)
			
			draw_line(LineStartPos, LineEndPos, TEXT_COLOR, 1)
			

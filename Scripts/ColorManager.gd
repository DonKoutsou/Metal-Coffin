@tool
extends Node

class_name ColorManager

@export var styleBoxes : Array[StyleBoxFlat]
@export var bgStyleBoxes : Array[StyleBoxFlat]
@export var th : Theme

static var COLORS : Array[Color] = [
	Color("ff8a14"),
	Color("ffc315"),
	Color(1,1,1),
	Color(0.486, 0.597, 0.669, 1.0),
	Color(0.779, 1.0, 0.22, 1.0),
	Color(0.48, 0.515, 1.0, 1.0)
]

static var CurrentColor : int = 3:
	set(value):
		CurrentColor = value
		instance.UpdateColors()

static var instance : ColorManager

static func GetCurrentColor() -> Color:
	return COLORS[CurrentColor]

func _ready() -> void:
	instance = self
	UpdateColors()
		
func UpdateColors()-> void:
	var col = COLORS[CurrentColor]
	
	for g in styleBoxes:
		g.border_color = col
	
	for g in bgStyleBoxes:
		g.bg_color = col
		
	th.set_color("font_color", "Label", col)
	th.set_color("default_color", "RichTextLabel", col)
	
	th.set_color("caret_color", "LineEdit", col)
	th.set_color("clear_button_color", "LineEdit", col)
	th.set_color("font_color", "LineEdit", col)
	th.set_color("caret_color", "LineEdit", col)
	th.set_color("selection_color", "LineEdit", col)
	
	th.set_color("caret_color", "TextEdit", col)
	th.set_color("font_color", "TextEdit", col)
	th.set_color("font_placeholder_color", "TextEdit", col)
	th.set_color("font_selected_color", "TextEdit", col)
	
	th.set_color("font_color", "CheckBox", col)
	th.set_color("font_focus_color", "CheckBox", col)
	th.set_color("font_hover_color", "CheckBox", col)
	th.set_color("font_hover_pressed_color", "CheckBox", col)
	
	th.set_color("font_color", "Button", col)
	th.set_color("font_disabled_color", "Button", col)
	th.set_color("font_focus_color", "Button", col)
	
	th.set_color("font_color", "ProgressBar", col)

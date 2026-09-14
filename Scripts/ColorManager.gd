@tool
extends Node

class_name ColorManager

@export var styleBoxes : Array[StyleBoxFlat]
@export var bgStyleBoxes : Array[StyleBoxFlat]
@export var th : Theme

static var COLORS : Dictionary[String, Color] = {
	"ORANGE" : Color("ff8a14"),
	"YELLOW" : Color("ffc315"),
	"WHITE" : Color(1,1,1),
}



@export_color_no_alpha var col : Color = Color(1,1,1):
	set(value):
		col = value
		UpdateColors()

static var instance : ColorManager

func _ready() -> void:
	instance = self
	UpdateColors()
		
func UpdateColors()-> void:
	for g in styleBoxes:
		g.border_color = col
	
	for g in bgStyleBoxes:
		g.bg_color = col
	
	th.set_color("font_color", "Label", col)
	
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

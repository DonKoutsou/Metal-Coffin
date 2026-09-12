@tool
extends Resource

class_name HappeningText

@export var Text : String :
	set(value):
		Text = value
		emit_changed()
		
@export_file("*.png") var Pic : String:
	set(value):
		Pic = value
		emit_changed()

@tool
extends Resource

class_name StringList

@export var Texts : PackedStringArray

#@export_tool_button("Convert") var C = ConvertToPacked
#
#func ConvertToPacked() -> void:
	#for g in Strings:
		#Texts.append(g)

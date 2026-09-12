@tool
extends Happening_Option
class_name String_Happening_Option

@export_multiline var StringReply : String:
	set(value):
		StringReply = value
		emit_changed()

func OptionResault(_EventOrigin : MapSpot) -> String:
	return StringReply

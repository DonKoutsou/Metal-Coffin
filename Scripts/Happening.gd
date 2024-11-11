extends Resource
class_name Happening

@export var HappeningName : String
@export var HappeningText : String
@export var Options : Array[Happening_Option] = []

func GetOptionsCount() -> int:
	return Options.size()

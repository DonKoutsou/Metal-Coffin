extends Resource

class_name FlightManualEntry

@export var EntryName : String
@export_multiline var EntryDesc : String

func GetEntryName() -> String:
	return EntryName

func GetEntryYext() -> String:
	return EntryDesc

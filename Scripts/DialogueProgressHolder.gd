extends Node

class_name DialogueProgressHolder

var ToldDialogues : SpokenDialogueEntry

static var Instance : DialogueProgressHolder

func _ready() -> void:
	if (ToldDialogues == null):
		ToldDialogues = SpokenDialogueEntry.new()
	Instance = self
	
static func GetInstance() -> DialogueProgressHolder:
	return Instance

func IsDialogueSpoken(Diag : String) -> bool:
	return ToldDialogues.Diag.has(Diag)
func OnDialogueSpoken(Diag : String) -> void:
	ToldDialogues.Diag.append(Diag)

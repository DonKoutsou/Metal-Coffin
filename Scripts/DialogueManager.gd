extends Node

class_name DialogueManager

@export var DiagplScene : PackedScene

static var Instance : DialogueManager

func _ready() -> void:
	Instance = self

static func GetInstance():
	return Instance

func PlayDiag(Diags : Array[String]):
	var diag = DiagplScene.instantiate() as DialoguePlayer
	Ingame_UIManager.GetInstance().AddUI(diag)
	diag.PlayDialogue(Diags)

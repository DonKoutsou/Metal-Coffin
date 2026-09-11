@tool
extends Resource

class_name HappeningStage


#@export_file("*.png") var StagePic : String

@export var Texts : Array[HappeningText]
#@export_multiline var HappeningTexts : Array[String]
@export var Options : Array[Happening_Option] = []

func FindText(t : String) -> HappeningText:
	for g in Texts:
		if (g.Text == t):
			return g
	return null

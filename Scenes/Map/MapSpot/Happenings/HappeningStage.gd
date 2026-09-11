@tool
extends Resource

class_name HappeningStage


@export_file("*.png") var StagePic : String

@export var Texts : Array[HappeningText]
@export_multiline var HappeningTexts : Array[String]
@export var Options : Array[Happening_Option] = []

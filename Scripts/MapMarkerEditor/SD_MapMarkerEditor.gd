extends Resource

class_name SD_MapMarkerEditor

@export var Lines : Array[SD_MapMarkerLine]
@export var Texts : Array[SD_MapMarkerText]

func AddLine(Line : MapMarkerLine) -> void:
	Lines.append(Line.GetSaveData())

func AddText(Text : MapMarkerText) -> void:
	Texts.append(Text.GetSaveData())

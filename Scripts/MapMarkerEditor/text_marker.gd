extends Node2D

class_name MapMarkerText

func SetText(T : String) -> void:
	$Label.text = T
	
func UpdateCameraZoom(NewZoom : float) -> void:
	scale = Vector2(1.5 / (NewZoom), 1.5/ (NewZoom))

func GetSaveData() -> SD_MapMarkerText:
	var saveData = SD_MapMarkerText.new()
	saveData.pos = position
	saveData.Text = $Label.text
	return saveData

func LoadData(Data : SD_MapMarkerText):
	position = Data.pos
	$Label.text = Data.Text
	add_to_group("ZoomAffected")

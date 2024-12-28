extends Node2D

class_name MapMarkerText

func SetText(T : String) -> void:
	$Label.text = T
	
func CamZoomUpdated(NewZoom : float) -> void:
	scale = Vector2(1 / NewZoom, 1/ NewZoom)

func GetSaveData() -> SD_MapMarkerText:
	var saveData = SD_MapMarkerText.new()
	saveData.pos = position
	saveData.Text = $Label.text
	return saveData

func LoadData(Data : SD_MapMarkerText):
	position = Data.pos
	$Label.text = Data.Text
	add_to_group("LineMarkers")

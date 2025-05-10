extends Line2D

class_name MapMarkerLine

var LineLeangth : float = 0

func UpdateLine(Pos : Vector2, CamZoom : float) -> void:
	set_point_position(1, Pos)
	LineLeangth = Vector2(0,0).distance_to(get_point_position(1))
	$Label.text = var_to_str(roundi(Map.PixelDistanceToKm(LineLeangth / CamZoom / 2))) + " km"
	$Label.position = (get_point_position(1) / 2) - ($Label.size / 2)
	$Label.pivot_offset = $Label.size / 2

func CamZoomUpdated(NewZoom : float) -> void:
	width = 2 / NewZoom
	$Label.scale = Vector2(1.5 / NewZoom, 1.5 / NewZoom)

func GetSaveData() -> SD_MapMarkerLine:
	var saveData = SD_MapMarkerLine.new()
	saveData.pos = position
	for g in get_point_count():
		saveData.Pointpos.append(get_point_position(g))
	saveData.LineLeangth = LineLeangth
	return saveData

func LoadData(Data : SD_MapMarkerLine):
	position = Data.pos
	for g in Data.Pointpos:
		add_point(g)
	LineLeangth = Data.LineLeangth
	$Label.text = var_to_str(roundi(LineLeangth)) + " km"
	$Label.position = (get_point_position(1) / 2) - ($Label.size / 2)
	$Label.pivot_offset = $Label.size / 2
	add_to_group("LineMarkers")

func _draw() -> void:
	draw_circle(points[0], points[0].distance_to(points[1]), Color(1,0.274,0.083), false)

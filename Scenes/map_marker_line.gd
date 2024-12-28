extends Line2D

class_name MapMarkerLine

var LineLeangth : float = 0

func UpdateLine(Pos : Vector2, CamZoom : float) -> void:
	set_point_position(1, Pos)
	LineLeangth = Vector2(0,0).distance_to(get_point_position(1))
	$Label.text = var_to_str(roundi(LineLeangth / CamZoom))
	$Label.position = (get_point_position(1) / 2) - ($Label.size / 2)
	$Label.pivot_offset = $Label.size / 2

func CamZoomUpdated(NewZoom : float) -> void:
	width = 2 / NewZoom
	$Label.scale = Vector2(1 / NewZoom, 1/ NewZoom)

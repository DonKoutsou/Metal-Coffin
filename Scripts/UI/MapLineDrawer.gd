extends Node2D

class_name MapLineDrawer

var Lines : Array

@export var RoadLines : bool = false
@export var ResizeLinesWithZoom : bool = false

func AddLines(L : Array) -> void:
	if (ResizeLinesWithZoom):
		add_to_group("ZoomAffected")
	Lines.append_array(L)
	DrawLines()

func DrawLines() -> void:
	for g in get_children():
		g.queue_free()
	
	for points in Lines:
		var L = Line2D.new()
		L.use_parent_material = true
		L.width = 20
		if (!RoadLines):
			L.default_color = Color(1,1,1, 1)
		else:
			L.width = 4
		add_child(L)
		L.global_position = points[0]
		#L.default_color = Color("0ca50a")
		#L.add_point(Vector2.ZERO, 0)
		for z in points.size():
			L.add_point(points[z] - L.global_position, z)

func UpdateCameraZoom(NewZoom : float) -> void:
	for g in get_children():
		g.width =  2 / NewZoom

#func _draw() -> void:
	#
	#for g in Lines:
		#draw_polyline(g, Color(1,1,1,1), 10, true)

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
		
		L.joint_mode = Line2D.LINE_JOINT_ROUND
		L.begin_cap_mode = Line2D.LINE_CAP_ROUND
		L.end_cap_mode = Line2D.LINE_CAP_ROUND
		L.round_precision = 4
		
		L.use_parent_material = true
		L.width = 20
		if (!RoadLines):
			L.default_color = Color(1,1,1, 1)
		else:
			#L.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			#L.texture = load("res://Assets/Sand/Tiles093_1K-PNG_Color.png")
			L.default_color = Color(0,0,0, 1)
			L.width = 1
		add_child(L)
		L.global_position = points[0]
		#L.default_color = Color("0ca50a")
		#L.add_point(Vector2.ZERO, 0)
		for z in points.size():
			L.add_point(points[z] - L.global_position, z)

func UpdateCameraZoom(NewZoom : float) -> void:
	for g in get_children():
		g.width =  2 / NewZoom
		g.visible = NewZoom <= 0.5

#func _draw() -> void:
	#
	#for g in Lines:
		#draw_polyline(g, Color(1,1,1,1), 10, true)

extends Node2D

class_name MapLineDrawer

var Lines : Array

func AddLines(L : Array) -> void:
	Lines.append_array(L)
	DrawLines()

func DrawLines() -> void:
	for g in get_children():
		g.queue_free()
	
	for points in Lines:
		var L = Line2D.new()
		L.use_parent_material = true
		L.width = 20
		add_child(L)
		L.global_position = points[0]
		#L.add_point(Vector2.ZERO, 0)
		for z in points.size():
			L.add_point(points[z] - L.global_position, z)

#func _draw() -> void:
	#
	#for g in Lines:
		#draw_polyline(g, Color(1,1,1,1), 10, true)

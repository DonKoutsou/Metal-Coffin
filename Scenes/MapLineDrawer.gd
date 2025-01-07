extends Node2D

class_name MapLineDrawer

var Lines : Array

func AddLines(L : Array) -> void:
	Lines.append_array(L)
	queue_redraw()

func _draw() -> void:
	for g in Lines:
		draw_polyline(g, Color(1,1,1,1), 10, true)

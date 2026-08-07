@tool
extends Control

class_name DispositionStatsUI

@export var DispositionColors : PackedColorArray = []

var points : PackedVector2Array

var offset : float = 0

func _process(delta: float) -> void:
	offset = min(1, offset + delta * 4)
	queue_redraw()
	if (offset == 1):
		set_process(false)
	queue_redraw()

func UpdateStats(stats : PackedVector2Array) -> void:
	points = stats
	set_process(true)
	offset = 0

func _draw() -> void:
	var finalPoints : PackedVector2Array
	for point in points:
		finalPoints.append((size / 2).slerp(point, offset))
		 
	draw_polygon(finalPoints, DispositionColors)
	for g in finalPoints.size():
		var pos = finalPoints[g]
		draw_circle(pos, 2, Color(1,1,1))

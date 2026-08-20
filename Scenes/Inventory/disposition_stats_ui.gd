@tool
extends Control

class_name DispositionStatsUI

@export var DispositionColors : PackedColorArray = []

var points : PackedVector2Array
var ItemPoints : PackedVector2Array

var offset : float = 0

func UpdateOffset(newOffset : float) -> void:
	offset = newOffset
	queue_redraw()

func UpdateStats(stats : PackedVector2Array, ItemStats : PackedVector2Array) -> void:
	points = stats
	ItemPoints = ItemStats
	set_process(true)
	offset = 0
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_method(UpdateOffset, 0.0, 1.0, 0.5)
	

func _draw() -> void:
	var finalPoints : PackedVector2Array
	var finalItemPoints : PackedVector2Array
	for point in points:
		finalPoints.append((size / 2).slerp(point, offset))
	
	for point in ItemPoints:
		finalItemPoints.append((size / 2).slerp(point, offset))
	
	draw_polygon(finalItemPoints, DispositionColors)
	draw_polygon(finalPoints, [Color(1,1,1)])
	
	for g in finalPoints.size():
		var pos = finalPoints[g]
		draw_circle(pos, 2, Color(1,1,1))
	for g in finalItemPoints.size():
		var pos = finalItemPoints[g]
		draw_circle(pos, 2, Color(1,1,1))

@tool
extends Control

class_name CaptainDispositionUI

@export var LineAmm : int = 5

var labels : Array[Label]

var CharacterStats : Dictionary[DispositionManager.Dispositions, float] = {
	DispositionManager.Dispositions.KINETIC : 1.0,
	DispositionManager.Dispositions.ELECTRICAL : 0.1,
	DispositionManager.Dispositions.THERMAL : 0.3,
	DispositionManager.Dispositions.MAGNETIC : 0.4,
	DispositionManager.Dispositions.RADIANT : 0.5,
}

@export var DispositionColors : PackedColorArray = []

func SetStats(ch : Captain) -> void:
	CharacterStats = ch.Disposition
	queue_redraw()
	
func _ready() -> void:
	for g in DispositionManager.Dispositions:
		var l = Label.new()
		add_child(l)
		labels.append(l)
		l.add_theme_font_size_override("normal", 12)

func _draw() -> void:
	var PointAmm = DispositionManager.Dispositions.size()
	var Radius = min(size.x, size.y) / 2.0 - 40


	var stats : PackedVector2Array = []
	var statCols : PackedColorArray = []
	for g in CharacterStats:
		var m = Helper.normalize_value(g, 0, CharacterStats.size())
		var rad = Radius * min(1, CharacterStats[g] * 2)
		var pointX = cos(m * (PI * 2) - 0.32)
		var pointY = sin(m * (PI * 2) - 0.32)
		stats.append(Vector2(pointX, pointY) * rad + size / 2.0)
		statCols.append(Color("ffc315"))
		
		labels[g].text = DispositionManager.Dispositions.keys()[g]
		labels[g].position = Vector2(pointX, pointY) * Radius + size / 2.0 - labels[g].size / 2.0
		if (labels[g].position.y < size.y / 2):
			labels[g].position -= Vector2(0,10)
		else:
			labels[g].position += Vector2(0,10)
	

	draw_polygon(stats, DispositionColors)
	for g in stats.size():
		var pos = stats[g]
		draw_circle(pos, 2, Color(1,1,1))

		
	
	var points : Array[PackedVector2Array]
	for g in range(0, LineAmm - 1):
		var arr : PackedVector2Array = []
		points.append(arr)

	for g in range(0, PointAmm):
		#we normalise the current point
		var m = Helper.normalize_value(g, 0, PointAmm)
		var pointX = cos(m * (PI * 2) - 0.32)
		var pointY = sin(m * (PI * 2) - 0.32)
		draw_line(size / 2.0, Vector2(pointX, pointY) * Radius + size / 2.0, Color(1,1,1), 1, true)
		for z in range(1, LineAmm, 1):
			
			var f = Helper.normalize_value(z, 0, LineAmm - 1)
			var rad = Radius * f

			#draw_circle(Vector2(pointX, pointY) + size / 2.0, 10, Color(1,0,0))
			var lineIndex = wrap(z - 1, 0, LineAmm )
			#print(lineIndex)
			points[lineIndex].append(Vector2(pointX, pointY) * rad + size / 2.0)
			
	for g in points:
		g.append(g[0])
		draw_polyline(g, Color(1.0, 1.0, 1.0, 1.0), 1, true)
	
	

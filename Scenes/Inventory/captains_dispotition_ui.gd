@tool
extends Control

class_name CaptainDispositionUI

@export var StatsDraw : DispositionStatsUI
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
	if (Engine.is_editor_hint()):
		GetCharacterEditorDisp(ch)
	else:
		CharacterStats = ch.disp
	queue_redraw()

func GetCharacterEditorDisp(ch : Captain) -> void:
	for g in CharacterStats:
		CharacterStats[g] = 0
	for g in ch.StartingItems:
		if (g is ShipPart):
			CharacterStats[g.disp] += g.DispositionAmm
	
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
	stats.resize(CharacterStats.size())
	for g in CharacterStats:
		var m = Helper.normalize_value(g, 0, CharacterStats.size())
		var rad = Radius * clamp(CharacterStats[g], 0.1, 1)
		var pointX = cos(m * (PI * 2) - 0.32)
		var pointY = sin(m * (PI * 2) - 0.32)
		stats[g] = Vector2(pointX, pointY) * rad + size / 2.0
		
		labels[g].text = DispositionManager.Dispositions.keys()[g]
		labels[g].position = Vector2(pointX, pointY) * Radius + size / 2.0 - labels[g].size / 2.0
		if (labels[g].position.y < size.y / 2):
			labels[g].position -= Vector2(0,10)
		else:
			labels[g].position += Vector2(0,10)

	StatsDraw.UpdateStats(stats)
		
	
	var points : Array[PackedVector2Array] = []
	points.resize(LineAmm - 1)
	
	for g in range(0, LineAmm - 1):
		var arr : PackedVector2Array = []
		arr.resize(PointAmm + 1)
		points[g] = arr

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
			var lineIndex = wrap(z - 1, 0, LineAmm)
			#print(lineIndex)
			points[lineIndex][g] = Vector2(pointX, pointY) * rad + size / 2.0
			
	for g in points:
		g[PointAmm] = g[0]
		draw_polyline(g, Color(1.0, 1.0, 1.0, 1.0), 1, true)
	
	

extends Radar

class_name PlayerRadar

var RadarCircle : PackedVector2Array
var CurrentRadarPointToEvaluate : int = 0

func _ready() -> void:
	super()
	if (RadarCircle.size() == 0):
		RadarCircle = get_circle_points(110)

func UpdateVizRange(rang : float):
	super(rang)
	var NewRange = max(rang, 110)
	RadarCircle = get_circle_points(NewRange, NewRange / 5.0)
	CurrentRadarPointToEvaluate = wrap(CurrentRadarPointToEvaluate, 0, RadarCircle.size())


func EvaluateRadarTargets(Altitude : float) -> void:
	for g in InsideRadar:
		if (TopographyMap.WithinLineOfSight(global_position, Altitude, g.global_position, g.Altitude)):
			g.OnShipSeen(self)
		else:
			g.OnShipUnseen(self)

func EvaluateRadarrPoint(Altitude : float) -> void:
	#var PointToEvaluate : Vector2 = RadarCircle[CurrentRadarPointToEvaluate]
	for g in 2:
		var Dir = GetPointInCircle(CurrentRadarPointToEvaluate, CurrentVisualRange / 5.0)
		var MaxPoint = Dir * CurrentVisualRange
		var GlobalPoint = global_position + MaxPoint
		var EvaluatedPoint = TopographyMap.GetCollisionPoint(global_position, Altitude, GlobalPoint, 10000)
		RadarCircle[CurrentRadarPointToEvaluate] = EvaluatedPoint - global_position
		CurrentRadarPointToEvaluate = wrap(CurrentRadarPointToEvaluate + 1, 0, RadarCircle.size())

func GetShipRadarLine() -> PackedVector2Array:
	var GlobalPoints : PackedVector2Array
	for g in RadarCircle:
		GlobalPoints.append(g + global_position)
	return GlobalPoints

func GetPointInCircle(Point : int, num_points : int = 20) -> Vector2:
	var angle = float(Point) / float(num_points) * PI * 2.0
	return Vector2(cos(angle), sin(angle))

func get_circle_points(radius: float, num_points: int = 20) -> PackedVector2Array:
	var circle_points = PackedVector2Array()
	for i in num_points:
		var angle = float(i) / float(num_points) * PI * 2.0
		var pt = Vector2(cos(angle), sin(angle)) * radius
		circle_points.append(pt)
	# Optionally close the loop:
	circle_points.append(circle_points[0])
	return circle_points

extends Node2D

class_name CircleDrawer

@export var ShipControllerEvent : ShipControllerEventHandler
@export var Col : Color

var circles : Array[PackedVector2Array] = []   # Now each is a polygon (radar hull)
var intersections = {}

var ControlledShip : PlayerDrivenShip
var ControlledShipPos : Vector2
var CamZoom = 1

var ClusterTH : Thread

func _ready() -> void:
	ControlledShip = ShipControllerEvent.CurrentControlled
	ShipControllerEvent.connect("OnControlledShipChanged", UpdateControlledShip)

func UpdateControlledShip(NewShip : PlayerDrivenShip) -> void:
	ControlledShip = NewShip
	if ControlledShip:
		ControlledShipPos = ControlledShip.global_position

# === MAIN: NEW INPUT ===
# Each element is a PackedVector2Array representing the "hull" polygon.
func UpdatePolygons(hulls: Array[PackedVector2Array]) -> void:
	if ClusterTH:
		ClusterTH.wait_to_finish()
	circles = []
	for hull in hulls:
		circles.append(hull.duplicate())
	ClusterTH = Thread.new()
	ClusterTH.start(ThreadProcessIntersections)

func find_or_create_cluster(clusters:Array, circle_index:int):
	for cluster in clusters:
		if circle_index in cluster:
			return cluster
	var new_cluster = []
	clusters.append(new_cluster)
	return new_cluster

func polygons_intersect(poly_a: PackedVector2Array, poly_b: PackedVector2Array) -> bool:
	var res = Geometry2D.intersect_polygons(poly_a, poly_b)
	return res.size() > 0

func ThreadProcessIntersections() -> Dictionary:
	var clusters = []
	for i in range(0, circles.size()):
		for j in range(i + 1, circles.size()):
			if polygons_intersect(circles[i], circles[j]):
				var cluster1 = find_or_create_cluster(clusters, i)
				var cluster2 = find_or_create_cluster(clusters, j)
				if cluster1 != cluster2:
					cluster1.append_array(cluster2)
					clusters.erase(cluster2)
				if i not in cluster1:
					cluster1.append(i)
				if j not in cluster1:
					cluster1.append(j)
	var intersects = {}
	for index in range(clusters.size()):
		intersects[index] = clusters[index]
	call_deferred("ClusterCalcFinished")
	return intersects

func ClusterCalcFinished() -> void:
	if ClusterTH:
		intersections = ClusterTH.wait_to_finish()
		ClusterTH = null
	if ControlledShip:
		ControlledShipPos = ControlledShip.global_position
	queue_redraw()

# Merge all polygons in a cluster into a single polygon (for outline drawing)
func merge_cluster_polygons(cluster: Array) -> Array[PackedVector2Array]:
	if not cluster or cluster.size() == 0:
		return []
	var merged : Array[PackedVector2Array] = [ circles[cluster[0]] ]
	for i in range(1, cluster.size()):
		var next_poly = circles[cluster[i]]
		var new_merged : Array[PackedVector2Array] = []
		for base_poly in merged:
			var merged_piece = Geometry2D.merge_polygons(base_poly, next_poly)
			if merged_piece.size():
				new_merged.append_array(merged_piece)
			else:
				# (No overlap)
				new_merged.append(base_poly)
				new_merged.append(next_poly)
		merged = new_merged
	merged[0].append(merged[0][0])
	return merged

func UpdateCameraZoom(NewVal : float) -> void:
	CamZoom = NewVal

func _draw():
	DrawRuller()
	
	var Lines : Array[PackedVector2Array]
	var intersectingcircles = []
	if (intersections.size() > 0):
		for g in intersections.size():
			var cluster = intersections.values()[g]
			if (not cluster or cluster.size() == 0):
				continue
			var merged_polygons = merge_cluster_polygons(cluster)
			for poly in merged_polygons:
				if poly.size() > 1:
					Lines.append(FromPolylineToLine(poly))
					#draw_polyline(poly, Col, 1 / CamZoom, true)
			# Keep note of drawn circle indices to avoid re-drawing
			for circ in cluster:
				intersectingcircles.append(circ)
	
	# Draw non-intersecting individual polygons
	for g in circles.size():
		if g in intersectingcircles:
			continue
		var poly = circles[g]
		if poly.size() > 1:
			Lines.append(FromPolylineToLine(poly))
			#draw_polyline(poly, Col, 1 / CamZoom, true)
	
	for g in Lines:
		draw_multiline(g, Col, 1 / CamZoom, true)
	
func FromPolylineToLine(Polyline : PackedVector2Array) -> PackedVector2Array:
	var Line : PackedVector2Array
	for PointIndex in Polyline.size():
		var NextIndex = wrap(PointIndex + 1, 0, Polyline.size())
		Line.append(Polyline[PointIndex])
		Line.append(Polyline[NextIndex])
	return Line

func DrawRuller() -> void:
	if ControlledShip == null or not ControlledShip.RadarWorking:
		return
	var LineW = 0.5 / CamZoom
	var vizrange = ControlledShip.Cpt.GetStatFinalValue(STAT_CONST.STATS.VISUAL_RANGE)
	if not ControlledShip.RadarWorking:
		vizrange = 110
	if vizrange == 110:
		vizrange *= WeatherManage.GetInstance().GetVisibilityInPosition(ControlledShipPos, WeatherManage.GetLightAmm())

	for g in 3:
		draw_circle(ControlledShipPos, vizrange / 3 * (g + 1), Color(100, 100, 100, 0.3), false, LineW, true)

	var Next = rotation_degrees
	var Num = 90

	var Lines : PackedVector2Array

	for g in 12:
		Lines.append(Vector2(vizrange / 3,0).rotated(deg_to_rad(Next)) + ControlledShipPos)
		Lines.append(Vector2(vizrange,0).rotated(deg_to_rad(Next)) + ControlledShipPos)
		Next -= 30
		Num -= 30
		if Num == 0:
			Num = 360

	draw_multiline(Lines, Color(100, 100, 100, 0.3), LineW, true)

# Optionally: provide a helper to generate circle polygon points
func get_circle_polygon(center: Vector2, rad : float, samples:int = 100) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(samples):
		var angle = float(i) / float(samples) * PI * 2.0
		points.append(center + Vector2(rad * cos(angle), rad * sin(angle)))
	points.append(points[0])
	return points

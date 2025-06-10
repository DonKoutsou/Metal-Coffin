extends Node2D

class_name CircleDrawer

@export var ShipControllerEvent : ShipControllerEventHandler

@export var Col : Color

var circles = []

var intersections = {}

var ControlledShip : PlayerDrivenShip

var CamZoom = 1

var ClusterTH : Thread
# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#$AnimationPlayer.play("loop")

func _ready() -> void:
	ControlledShip = ShipControllerEvent.CurrentControlled
	ShipControllerEvent.connect("OnControlledShipChanged", UpdateControlledShip)
	

func UpdateControlledShip(NewShip : PlayerDrivenShip) -> void:
	ControlledShip = NewShip

func UpdateCircles(Circl : Array[PackedVector2Array])-> void:
	circles.clear()
	circles.append_array(Circl)
	if (ClusterTH != null):
		ClusterTH.wait_to_finish()
	ClusterTH = Thread.new()
	ClusterTH.start(ThreadProcessIntersections)
	#PackedVector2Array([g.global_position, Vector2(100, 0)])
func find_or_create_cluster(clusters, circle_index):
		for cluster in clusters:
			if circle_index in cluster:
				return cluster
		var new_cluster = []
		clusters.append(new_cluster)
		return new_cluster

func ThreadProcessIntersections() -> Dictionary:
	#circles.clear()
	var clusters = []
	#clusters.clear()
	#$Area2D3.global_position = get_global_mouse_position()
	#for g in get_children():
		#if g is Node2D:
			#circles.append(PackedVector2Array([g.global_position, Vector2(100, 0)]))
	for i in range(0, circles.size()):
		for j in range(i + 1, circles.size()):
			var circle1_center = circles[i][0]
			var circle1_radius = circles[i][1].x
			var circle2_center = circles[j][0]
			var circle2_radius = circles[j][1].x

			# Calculate distance between the centers
			var distance = circle1_center.distance_to(circle2_center)

			# Check if circles intersect
			if distance < (circle1_radius + circle2_radius):
				var cluster1 = find_or_create_cluster(clusters, i)
				var cluster2 = find_or_create_cluster(clusters, j)

				if cluster1 != cluster2:
					# Merge clusters if they are different
					cluster1.append_array(cluster2)
					clusters.erase(cluster2)

				if i not in cluster1:
					cluster1.append(i)
				if j not in cluster1:
					cluster1.append(j)

	# Convert clusters to a dictionary
	var intersects = {}
	for index in range(clusters.size()):
		intersects[index] = clusters[index]
	
	call_deferred("ClusterCalcFinished")
	
	return intersects

func ClusterCalcFinished() -> void:
	intersections = ClusterTH.wait_to_finish()
	ClusterTH = null
	queue_redraw()



func get_circle_polygon(center: Vector2, rad : float) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(100):
		var angle = float(i) / float(100) * PI * 2.0
		points.append(center + Vector2(rad * cos(angle), rad * sin(angle)))
	points.append(points[0])
	return points

func CamZoomUpdated(NewVal : float) -> void:
	CamZoom = NewVal

func _draw():
	DrawRuller()
	
	var intersectingcircles = []
	if (intersections.size() > 0):
		for g in intersections.size():
			var cluster = intersections.values()[g]
			if (cluster.size() == 0):
				continue
			var polyg : Array[PackedVector2Array] = [[]]
			for z in cluster.size():
				var circ1 = cluster[z]
				intersectingcircles.append(circ1)
				#var clust2 = cluster[z + 1]
				var pol1 = get_circle_polygon(circles[circ1][0], circles[circ1][1].x)
				var newpoly : Array[PackedVector2Array]
				for p in polyg.size():
					var origpoly = polyg
					var newpolyg = Geometry2D.merge_polygons(pol1, origpoly[p])
					newpoly.append_array(newpolyg)
				polyg = newpoly

			var newpolygon : Array[PackedVector2Array] = [[]]
			for f in polyg.size():
				newpolygon = Geometry2D.merge_polygons(newpolygon[0],polyg[f])
			for f in newpolygon.size():
				newpolygon[f].append(newpolygon[f][0])
				draw_polyline(newpolygon[f], Col, 2 / CamZoom, true)
	for g in circles.size():
		if (intersectingcircles.has(g)):
			continue
		draw_polyline(get_circle_polygon(circles[g][0], circles[g][1].x), Col, 2 / CamZoom, true)
	
	
			
func DrawRuller() -> void:
	if (ControlledShip == null or !ControlledShip.RadarWorking):
		return
	var shippos = ControlledShip.global_position
	var LineW = 1/CamZoom
	var vizrange = ControlledShip.Cpt.GetStatFinalValue(STAT_CONST.STATS.VISUAL_RANGE)
	if(!ControlledShip.RadarWorking):
		vizrange = 90
	
	
	for g in 3:
		draw_circle(shippos, vizrange / 3 * (g + 1), Color(100, 100, 100), false, LineW, true)

	var Next = rotation_degrees
	var Num = 90
	for g in 12:
		draw_line(Vector2(vizrange / 3,0).rotated(deg_to_rad(Next)) + shippos, Vector2(vizrange,0).rotated(deg_to_rad(Next)) + shippos, Color(100, 100, 100), LineW, true)





		#var Text = var_to_str(Num).replace(".0", "")
		#var TextSize = (2/CamZoom)*6
		#var Textpos = Vector2(vizrange + 50, 0).rotated(deg_to_rad(Next))
		#Textpos += Vector2.ZERO.direction_to(Textpos) * TextSize
		#Textpos.x -= Text.length() * (TextSize / 4)
		#Textpos.y += TextSize / 4
		#draw_string(ThemeDB.fallback_font, Textpos + shippos, Text, HORIZONTAL_ALIGNMENT_LEFT, -1, TextSize)

		Next -= 30
		Num -= 30
		if (Num == 0):
			Num = 360
	#for g in 3:
		#draw_circle(shippos, 50 / CamZoom * (g + 1), Color(100, 100, 100), false, 1/CamZoom, true)
	#var Next = rotation_degrees
#
	#for g in 12:
		#draw_line(Vector2(50 / CamZoom,0).rotated(deg_to_rad(-Next)) + shippos, Vector2(150 / CamZoom,0).rotated(deg_to_rad(-Next)) + shippos, Color(100, 100, 100), 1/CamZoom, true)
		#var Text = var_to_str(abs(rotation_degrees + 90 - Next)).replace(".0", "")
		#var TextSize = (2/CamZoom)*6
		#var Textpos = Vector2(160 / CamZoom, 0).rotated(deg_to_rad(-Next))
		#Textpos += Vector2.ZERO.direction_to(Textpos) * TextSize
		#Textpos.x -= Text.length() * (TextSize / 4)
		#Textpos.y += TextSize / 4
		#draw_string(ThemeDB.fallback_font, Textpos + shippos, Text, HORIZONTAL_ALIGNMENT_LEFT, -1, TextSize)
		#Next += 30
func merge_cluster_polygons(cluster: Array) :
	var merged_polygon = PackedVector2Array()
	for circ in cluster:
		var polygon = get_circle_polygon(circles[circ][0], circles[circ][1])
		if merged_polygon.size() == 0:
			merged_polygon = polygon
		else:
			merged_polygon = Geometry2D.merge_polygons(merged_polygon, polygon)
	return merged_polygon

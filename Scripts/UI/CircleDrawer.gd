extends Node2D

class_name CircleDrawer

@export var ShipControllerEvent : ShipControllerEventHandler

@export var Col : Color

var circles = []

var intersections = {}

var ControlledShip : PlayerDrivenShip
var ControlledShipPos : Vector2

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
	ControlledShipPos = ControlledShip.global_position

func UpdateCircles(Circl : Array[PackedVector2Array])-> void:
	if (ClusterTH != null):
		ClusterTH.wait_to_finish()
		
	circles.clear()
	circles.append_array(Circl)
	
	ClusterTH = Thread.new()
	ClusterTH.start(ThreadProcessIntersections)

func find_or_create_cluster(clusters, circle_index):
		for cluster in clusters:
			if circle_index in cluster:
				return cluster
		var new_cluster = []
		clusters.append(new_cluster)
		return new_cluster

func ThreadProcessIntersections() -> Dictionary:
	var clusters = []
	for i in range(0, circles.size()):
		for j in range(i + 1, circles.size()):
			var circle1_center = circles[i][0]
			var circle1_radius = circles[i][1].x
			var circle2_center = circles[j][0]
			var circle2_radius = circles[j][1].x

			# Calculate distance between the centers
			var distance = circle1_center.distance_squared_to(circle2_center)

			# Check if circles intersect
			if distance < (circle1_radius + circle2_radius) * (circle1_radius + circle2_radius):
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
	if (ClusterTH != null):
		intersections = ClusterTH.wait_to_finish()
		ClusterTH = null
	if (ControlledShip != null):
		ControlledShipPos = ControlledShip.global_position
	queue_redraw()



func get_circle_polygon(center: Vector2, rad : float) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(100):
		var angle = float(i) / float(100) * PI * 2.0
		points.append(center + Vector2(rad * cos(angle), rad * sin(angle)))
	points.append(points[0])
	return points

func UpdateCameraZoom(NewVal : float) -> void:
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
				draw_polyline(newpolygon[f], Col, 1 / CamZoom, true)
	for g in circles.size():
		if (intersectingcircles.has(g)):
			continue
		draw_polyline(get_circle_polygon(circles[g][0], circles[g][1].x), Col, 1 / CamZoom, true)
	
	
			
func DrawRuller() -> void:
	if (ControlledShip == null or !ControlledShip.RadarWorking):
		return
	#var shippos = ControlledShip.global_position
	var LineW = 0.5/CamZoom
	var vizrange = ControlledShip.Cpt.GetStatFinalValue(STAT_CONST.STATS.VISUAL_RANGE)
	if(!ControlledShip.RadarWorking):
		vizrange = 110
	
	if (vizrange == 110):
		vizrange *= WeatherManage.GetVisibilityInPosition(ControlledShipPos)
	
	
	for g in 3:
		draw_circle(ControlledShipPos, vizrange / 3 * (g + 1), Color(100, 100, 100, 0.3), false, LineW, true)

	var Next = rotation_degrees
	var Num = 90
	
	var Lines : PackedVector2Array
	
	for g in 12:
		Lines.append(Vector2(vizrange / 3,0).rotated(deg_to_rad(Next)) + ControlledShipPos)
		Lines.append(Vector2(vizrange,0).rotated(deg_to_rad(Next)) + ControlledShipPos)
		#draw_line(, , Color(100, 100, 100, 0.3), LineW, true)
		
		Next -= 30
		Num -= 30
		if (Num == 0):
			Num = 360
	
	draw_multiline(Lines, Color(100, 100, 100, 0.3), LineW, true)
	#Num = 0
	#
	#for g in 4:
		#var text = "Visual Range"
		#if (g % 2):
			#var pos = Vector2(100,0).rotated(deg_to_rad(Next)) + shippos
			#draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(1,1,1), TextServer.JUSTIFICATION_AFTER_LAST_TAB,TextServer.DIRECTION_AUTO, TextServer.ORIENTATION_HORIZONTAL)
		#else:
			#var pos = Vector2(100,0).rotated(deg_to_rad(Next)) + shippos
			#pos.y -= 4 * 8
			#draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(1,1,1), TextServer.JUSTIFICATION_AFTER_LAST_TAB,TextServer.DIRECTION_AUTO, TextServer.ORIENTATION_VERTICAL)
		#
		#Next -= 90
		#Num -= 90
		#if (Num == 0):
			#Num = 360
	


		#var Text = var_to_str(Num).replace(".0", "")
		#var TextSize = (2/CamZoom)*6
		#var Textpos = Vector2(vizrange + 50, 0).rotated(deg_to_rad(Next))
		#Textpos += Vector2.ZERO.direction_to(Textpos) * TextSize
		#Textpos.x -= Text.length() * (TextSize / 4)
		#Textpos.y += TextSize / 4
		#draw_string(ThemeDB.fallback_font, Textpos + shippos, Text, HORIZONTAL_ALIGNMENT_LEFT, -1, TextSize)

		
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

extends Node2D

class_name CircleDrawer

@export var Col : Color

var circles = []
var clusters = []
var intersections = {}
var CamZoom = 1
# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#$AnimationPlayer.play("loop")
	
func UpdateCircles(Circl : Array[PackedVector2Array])-> void:
	circles.clear()
	circles.append_array(Circl)
	#PackedVector2Array([g.global_position, Vector2(100, 0)])
func find_or_create_cluster(circle_index):
		for cluster in clusters:
			if circle_index in cluster:
				return cluster
		var new_cluster = []
		clusters.append(new_cluster)
		return new_cluster

func _physics_process(_delta: float) -> void:
	#circles.clear()
	clusters.clear()
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
				var cluster1 = find_or_create_cluster(i)
				var cluster2 = find_or_create_cluster(j)

				if cluster1 != cluster2:
					# Merge clusters if they are different
					cluster1.append_array(cluster2)
					clusters.erase(cluster2)

				if i not in cluster1:
					cluster1.append(i)
				if j not in cluster1:
					cluster1.append(j)

	# Convert clusters to a dictionary
	intersections.clear()
	for index in range(clusters.size()):
		intersections[index] = clusters[index]
	
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
func merge_cluster_polygons(cluster: Array) :
	var merged_polygon = PackedVector2Array()
	for circ in cluster:
		var polygon = get_circle_polygon(circles[circ][0], circles[circ][1])
		if merged_polygon.size() == 0:
			merged_polygon = polygon
		else:
			merged_polygon = Geometry2D.merge_polygons(merged_polygon, polygon)
	return merged_polygon

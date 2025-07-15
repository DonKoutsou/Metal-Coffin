extends Node2D

class_name RegionLineDrawer


var BorderLines : Array

@export var ResizeLinesWithZoom : bool = false

func _DrawBorders(Spots : Array) -> void:
	var Lines : Dictionary[MapSpotCompleteInfo.REGIONS, Array] = {
		MapSpotCompleteInfo.REGIONS.MAMDU : [],
		MapSpotCompleteInfo.REGIONS.BAKYS : [],
		MapSpotCompleteInfo.REGIONS.KIRS : [],
		MapSpotCompleteInfo.REGIONS.ZAV : []
	}
	
	var Regions : Dictionary[MapSpotCompleteInfo.REGIONS, Array] = {
		MapSpotCompleteInfo.REGIONS.MAMDU : [],
		MapSpotCompleteInfo.REGIONS.BAKYS : [],
		MapSpotCompleteInfo.REGIONS.KIRS : [],
		MapSpotCompleteInfo.REGIONS.ZAV : []
	}
	
	for g in Spots:
		Regions[g.SpotInfo.Region].append(g)
	
	for Region in Regions.keys():
		var Line : Array[Vector2]
		for Spot in Regions[Region]:
			Line.append(Spot.global_position)
		
		Lines[Region] = Line

	var Hulls = calculate_convex_hulls(Lines)
	
	if (ResizeLinesWithZoom):
		add_to_group("ZoomAffected")

	for g in get_children():
		g.queue_free()
	
	for g in Hulls.keys():
		var points = Hulls[g]
		if (points.size() == 0):
			continue
		
		var poly = Polygon2D.new()
		poly.use_parent_material = true
		poly.polygon = points
		poly.color = Helper.GetColorForRegion(g)
		add_child(poly)

func calculate_convex_hulls(Lines : Dictionary[MapSpotCompleteInfo.REGIONS, Array]) -> Dictionary[MapSpotCompleteInfo.REGIONS, Array]:
	var hulls: Dictionary[MapSpotCompleteInfo.REGIONS, Array] = {
		MapSpotCompleteInfo.REGIONS.MAMDU : [],
		MapSpotCompleteInfo.REGIONS.BAKYS : [],
		MapSpotCompleteInfo.REGIONS.KIRS : [],
		MapSpotCompleteInfo.REGIONS.ZAV : []
	}
	for g in Lines.keys():
		
		var points = Lines[g]
		# Calculate convex hull for the current region
		var hull_points = create_convex_hull(points)
		hulls[g] = hull_points
		
	return hulls


func create_convex_hull(points: Array) -> Array:
	if (points.size() == 0):
		return []
	var Highestpoint = points[0]
	var Lowest = points[0]
	for g : Vector2 in points:
		if (g.y > Highestpoint.y):
			Highestpoint = g
		else: if (g.y < Lowest.y):
			Lowest = g
	
	var mindist = abs(Highestpoint.y - Lowest.y) / 4
	
	var ThreasholdTop = Highestpoint.y - mindist
	var ThreasholdBottom = Lowest.y + mindist
	
	var TopPoints : Array[Vector2]
	var BottomPOints : Array[Vector2]
	
	while (TopPoints.size() < 3):
		for g in points:
			if (g.y > ThreasholdTop):
				TopPoints.append(g)
		ThreasholdTop += 50
	
	while (BottomPOints.size() < 3):
		for g in points:
			if (g.y < ThreasholdBottom):
				BottomPOints.append(g)
		ThreasholdBottom += 50
			
	var HullPoints : Array
	
	TopPoints.sort_custom(sort_ascending)
	BottomPOints.sort_custom(sort_descending)
	
	TopPoints.insert(0, Vector2(-15000, TopPoints[0].y))
	TopPoints.append((Vector2(15000, TopPoints[TopPoints.size() - 1].y)))
	
	BottomPOints.insert(0, Vector2(15000, BottomPOints[BottomPOints.size() - 1].y))
	BottomPOints.append(Vector2(-15000, BottomPOints[0].y))
	
	HullPoints.append_array(TopPoints)
	HullPoints.append_array(BottomPOints)
	
	return HullPoints
	

func sort_ascending(a : Vector2, b : Vector2):
	if a.x < b.x:
		return true
	return false

func sort_descending(a : Vector2, b : Vector2):
	if a.x > b.x:
		return true
	return false
	

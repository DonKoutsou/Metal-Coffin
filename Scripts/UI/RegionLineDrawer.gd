extends Node2D

class_name RegionLineDrawer

@export var RegionTrans : float = 0.05

var BorderLines : Array

var BLines : Array[Line2D]
var Labels : Array[Label]

@export var ResizeLinesWithZoom : bool = false

func UpdateCameraZoom(NewZoom : float) -> void:
	visible = NewZoom < 1.5
	for g in BLines:
		g.width = 20 / NewZoom
	#for g in Labels:
		##g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		#g.set("theme_override_font_sizes/font_size", 120 / NewZoom)
	pass

var BorderThread : Thread

func _DrawBorders(Spots : Array) -> void:
	if (ResizeLinesWithZoom):
		add_to_group("ZoomAffected")

	for g in get_children():
		g.queue_free()
		
	BorderThread = Thread.new()
	
	var Lines : Dictionary[MapSpotCompleteInfo.REGIONS, Array] = {
		MapSpotCompleteInfo.REGIONS.MAMDU : [],
		MapSpotCompleteInfo.REGIONS.BAKYS : [],
		MapSpotCompleteInfo.REGIONS.KIRS : [],
	}
	
	var Regions : Dictionary[MapSpotCompleteInfo.REGIONS, Array] = {
		MapSpotCompleteInfo.REGIONS.MAMDU : [],
		MapSpotCompleteInfo.REGIONS.BAKYS : [],
		MapSpotCompleteInfo.REGIONS.KIRS : [],
	}
	
	for g in Spots:
		Regions[g.Region].append(g)
	
	for Region in Regions.keys():
		var Line : Array[Vector2]
		for Spot in Regions[Region]:
			Line.append(Spot.global_position)
		
		Lines[Region] = Line
	
	BorderThread.start(_DrawBordersTh.bind(Lines))
	
func _DrawBordersTh(Lines : Dictionary[MapSpotCompleteInfo.REGIONS, Array]) -> Dictionary[MapSpotCompleteInfo.REGIONS, Array]:

	var Hulls = calculate_convex_hulls(Lines)

	call_deferred("_DrawingEnded")
	
	return Hulls
	

func _DrawingEnded() -> void:
	var Hulls = BorderThread.wait_to_finish()
	
	for g in Hulls.keys():
		var points = Hulls[g]
		if (points.size() == 0):
			continue
		
		#var poly = Polygon2D.new()
		#poly.use_parent_material = true
		#poly.polygon = points
		#poly.color = Helper.GetInstance().GetColorForRegion(g)
		#poly.color.a = RegionTrans
		#add_child(poly)
		
		var l = Label.new()
		l.text = MapSpotCompleteInfo.REGIONS.keys()[g]
		l.add_theme_font_override("font", load("res://Fonts/Caudex-Bold.ttf"))
		Labels.append(l)
		add_child(l)
		l.set("theme_override_font_sizes/font_size", 1200)
		var ypos = points[0] + points[0].direction_to(points[points.size() - 1]) * (points[0].distance_to(points[points.size() - 1]) / 2)
		call_deferred("PositionLabel", l, Vector2(0, ypos.y))
		l.rotation = randf_range(-0.1, 0.1)
		l.modulate.a = RegionTrans
	
	for g in BorderLines:
		var l = Line2D.new()
		add_child(l)
		l.use_parent_material = true
		l.joint_mode = Line2D.LINE_JOINT_ROUND
		l.default_color = Color(0,0,0,RegionTrans)
		for p in g:
			l.add_point(p)
		BLines.append(l)

func PositionLabel(L : Label, pos : Vector2) -> void:
	var p = Vector2(pos.x - L.size.x / 2, pos.y - L.size.y / 2)
	L.position = p

func calculate_convex_hulls(Lines : Dictionary[MapSpotCompleteInfo.REGIONS, Array]) -> Dictionary[MapSpotCompleteInfo.REGIONS, Array]:
	var hulls: Dictionary[MapSpotCompleteInfo.REGIONS, Dictionary] = {
		MapSpotCompleteInfo.REGIONS.MAMDU : {"TopPoints" : [], "BottomPoints" : []},
		MapSpotCompleteInfo.REGIONS.BAKYS : {"TopPoints" : [], "BottomPoints" : []},
		MapSpotCompleteInfo.REGIONS.KIRS : {"TopPoints" : [], "BottomPoints" : []},
	}
	for g in Lines.keys():
		
		var points = Lines[g]
		# Calculate convex hull for the current region
		var hull_points = create_convex_hull(points)
		hulls[g] = hull_points
	
	#for g in hulls.keys().size():
		#var CurrentKey = hulls.keys()[g]
		#var currenthull = hulls[hulls.keys()[g]]
		#currenthull["TopPoints"] = SmoothLine(currenthull["TopPoints"])
		#currenthull["BottomPoints"] = SmoothLine(currenthull["BottomPoints"])
	
	var finalhulls: Dictionary[MapSpotCompleteInfo.REGIONS, Array] = {
		MapSpotCompleteInfo.REGIONS.MAMDU : [],
		MapSpotCompleteInfo.REGIONS.BAKYS : [],
		MapSpotCompleteInfo.REGIONS.KIRS : [],
	}
	
	for g in hulls.keys().size():
		#var CurrentKey = hulls.keys()[g]
		#var NextKey = hulls.keys()[g]
		
		#var CurrentFinalHull : Array
		
		#if (hulls.keys().size() < g + 1):
			#break

		var currenthull = hulls[hulls.keys()[g]]
		var CurrentTopPoints = currenthull["TopPoints"] as Array
		
		#var CurrentBottomPoints = currenthull["BottomPoints"] as Array
		
		#var nexthull = hulls[hulls.keys()[g + 1]]
		#var NextBottomPoints = nexthull["BottomPoints"]

		if (g > 0):
			var prevoushull = hulls[hulls.keys()[g - 1]]
			var previousBottomPoints = prevoushull["BottomPoints"] as Array
			
			for c : Vector2 in CurrentTopPoints:
				var foundpair : bool = false
				for p : Vector2 in previousBottomPoints:
					var dist = abs(c.x - p.x)
					if (dist < 500):
						var midpoint = c + c.direction_to(p) * (c.distance_to(p) / 2)
						
						var previndex = previousBottomPoints.find(p)
						var currentindex = CurrentTopPoints.find(c)
						
						previousBottomPoints.remove_at(previndex)
						previousBottomPoints.insert(previndex, midpoint)
						
						CurrentTopPoints.remove_at(currentindex)
						CurrentTopPoints.insert(currentindex, midpoint)
						
						foundpair = true
						break

				if (!foundpair):
					var newpoint = c
					
					newpoint.y += randf_range(500, 1000)

					for p : Vector2 in previousBottomPoints:
						if (newpoint.x >= p.x):
							
							var currentindex = CurrentTopPoints.find(c)
							CurrentTopPoints.remove_at(currentindex)
							CurrentTopPoints.insert(currentindex, newpoint)
					
							var previndex = previousBottomPoints.find(p)
							
							#previousBottomPoints.remove_at(previndex)
							previousBottomPoints.insert(previndex, newpoint)
							break
		else:
			for c : Vector2 in CurrentTopPoints:
				var currentindex = CurrentTopPoints.find(c)
				var newpoint = c
				newpoint.y += 3000
				CurrentTopPoints.remove_at(currentindex)
				CurrentTopPoints.insert(currentindex, newpoint)

		
		var CurrentBottomPoints = currenthull["BottomPoints"] as Array
		if (g < hulls.keys().size() - 1):
			var nexthull = hulls[hulls.keys()[g + 1]]
			var NextTopPoints = nexthull["TopPoints"] as Array
			
			for c : Vector2 in CurrentBottomPoints:
				var foundpair : bool = false
				for p : Vector2 in NextTopPoints:
					var dist = abs(c.x - p.x)
					if (dist < 500):
						var midpoint = c + c.direction_to(p) * (c.distance_to(p) / 2)
						
						var nextindex = NextTopPoints.find(p)
						var currentindex = CurrentBottomPoints.find(c)
						
						NextTopPoints.remove_at(nextindex)
						NextTopPoints.insert(nextindex, midpoint)
						
						CurrentBottomPoints.remove_at(currentindex)
						CurrentBottomPoints.insert(currentindex, midpoint)
						
						foundpair = true
						break

				if (!foundpair):
					var newpoint = c
					newpoint.y -= randf_range(500, 1000)

					for p : Vector2 in NextTopPoints:
						if (newpoint.x <= p.x):
							
							var currentindex = CurrentBottomPoints.find(c)
							CurrentBottomPoints.remove_at(currentindex)
							CurrentBottomPoints.insert(currentindex, newpoint)
					
							var nextindex = NextTopPoints.find(p)
							
							#previousBottomPoints.remove_at(previndex)
							NextTopPoints.insert(nextindex, newpoint)
							break
		else:
			for c : Vector2 in CurrentBottomPoints:
				var currentindex = CurrentBottomPoints.find(c)
				var newpoint = c
				newpoint.y -= 3000
				CurrentBottomPoints.remove_at(currentindex)
				CurrentBottomPoints.insert(currentindex, newpoint)
				
				
	for g in hulls.keys():
		var currenthull = hulls[g]
		var points : Array
		var toppoints = Helper.SmoothLine(currenthull["TopPoints"])
		points.append_array(toppoints)
		BorderLines.append(toppoints)
		var bottompoints = Helper.SmoothLine(currenthull["BottomPoints"])
		points.append_array(bottompoints)
		finalhulls[g] = points
		
	return finalhulls




func create_convex_hull(points: Array) -> Dictionary:
	
	if (points.size() == 0):
		return {"TopPoints" : [], "BottomPoints" : []}
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
	
	while (TopPoints.size() < 2 or ThreasholdTop < 500):
		for g in points:
			if (g.y > ThreasholdTop and !TopPoints.has(g)):
				TopPoints.append(g)
		ThreasholdTop += 50
		if (ThreasholdTop > 2000):
			break
	
	while (BottomPOints.size() < 2):
		for g in points:
			if (g.y < ThreasholdBottom and !BottomPOints.has(g)):
				BottomPOints.append(g)
		ThreasholdBottom += 50
		if (ThreasholdBottom > 2000):
			break
			
	var HullPoints : Dictionary = {"TopPoints" : [], "BottomPoints" : []}
	
	TopPoints.sort_custom(sort_ascending)
	BottomPOints.sort_custom(sort_descending)
	
	#var midpoint = TopPoints[0].y + abs(TopPoints[0].y - BottomPOints[0].y)
	
	TopPoints.insert(0, Vector2(-8000, TopPoints[0].y))
	#TopPoints.insert(0, Vector2(-9000, midpoint))
	#TopPoints.insert(0, Vector2(-8000, BottomPOints[0].y))
	
	
	TopPoints.append((Vector2(8000, TopPoints[TopPoints.size() - 1].y)))
	#TopPoints.append((Vector2(9000, midpoint)))
	#TopPoints.append((Vector2(8000, BottomPOints[BottomPOints.size() - 1].y)))
	
	BottomPOints.insert(0, Vector2(8000, BottomPOints[BottomPOints.size() - 1].y))
	BottomPOints.append(Vector2(-8000, BottomPOints[0].y))
	#BottomPOints.append(Vector2(-5000, midpoint))
	
	HullPoints["TopPoints"] = TopPoints
	HullPoints["BottomPoints"] = BottomPOints
	
	return HullPoints
	

func sort_ascending(a : Vector2, b : Vector2):
	if a.x < b.x:
		return true
	return false

func sort_descending(a : Vector2, b : Vector2):
	if a.x > b.x:
		return true
	return false
	

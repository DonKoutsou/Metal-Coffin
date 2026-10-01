extends Node

class_name MapHelper

@export var RegionColors : Dictionary[MapSpotCompleteInfo.REGIONS, Color]

static var Instance : MapHelper

func _ready() -> void:
	Instance = self

static func GetColorForRegion(R : MapSpotCompleteInfo.REGIONS):
	return Instance.RegionColors[R]

static func GetCityByName(CityName : String) -> MapSpot:
	var SpotGroups = ["CAPITAL", "CITY_CENTER", "VILLAGE"]
	var cities = []
	for g in SpotGroups:
		cities.append_array(Instance.get_tree().get_nodes_in_group(g))
	var CorrectCity : MapSpot
	for g in cities:
		var cit = g as MapSpot
		if (cit.GetSpotName() == CityName):
			CorrectCity = cit
			break
	return CorrectCity

static func GetClosestSpot(Pos : Vector2) -> MapSpot:
	var Closest : MapSpot
	var Dist = 99999999999999999
	for g in Instance.get_tree().get_nodes_in_group("City"):
		var Dist2 = Pos.distance_squared_to(g.global_position)
		if (Dist2 < Dist):
			Dist = Dist2
			Closest = g
			if (Dist < 200):
				break

	return Closest

static func GetSpotsCloserThan(Pos : Vector2, DistSquared : float) -> Array[MapSpot]:
	var Spots : Array[MapSpot]
	for g in Instance.get_tree().get_nodes_in_group("City"):
		var Dist2 = Pos.distance_squared_to(g.global_position)
		if (Dist2 < DistSquared):
			Spots.append(g)

	return Spots

static func GetSpotByName(CityName : String) -> MapSpot:
	var CorrectCity : MapSpot
	for g in Instance.get_tree().get_nodes_in_group("City"):
		var cit = g as MapSpot
		if (cit.GetSpotName() == CityName):
			CorrectCity = cit
			break
	return CorrectCity

static func FindPath(start_city: String, end_city: String) -> Array:
	#var cities = get_tree().get_nodes_in_group("EnemyDestinations")
	var queue = []
	var visited = {}
	var parent = {}
	
	# Initialize the BFS
	queue.append(start_city)
	visited[start_city] = true
	parent[start_city] = null
	
	# Perform the BFS
	while queue.size() > 0:
		var current_city = queue.pop_front()
		
		# If we reached the end_city, reconstruct the path
		if current_city == end_city:
			return Helper.reconstruct_path(parent, end_city)
		
		# Explore neighboring cities
		var Cit = GetCityByName(current_city)
		if (Cit.NeighboringCities.size() == 0):
			printerr(Cit.GetSpotName + " has no neighboring cities. Seems sus.")
		for neighbor in Cit.NeighboringCities:
			if not visited.has(neighbor):
				queue.append(neighbor)
				visited[neighbor] = true
				parent[neighbor] = current_city
	
	# If no path is found, return an empty array
	print("Failed to find a path from " + start_city + " to " + end_city)
	return []

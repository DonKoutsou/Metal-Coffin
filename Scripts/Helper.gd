extends Node

class_name Helper

@export var RegionColors : Dictionary[MapSpotCompleteInfo.REGIONS, Color]

static var Instance : Helper

func _ready() -> void:
	Instance = self
	set_physics_process(false)
	$CanvasLayer.visible = false

func _physics_process(delta: float) -> void:
	$CanvasLayer/TextureRect.pivot_offset = $CanvasLayer/TextureRect.size / 2
	$CanvasLayer/TextureRect.rotation = wrap($CanvasLayer/TextureRect.rotation + delta, 0, PI * 4)
	

func LoadThreaded(File : String) -> SignalObject:
	var Sign = SignalObject.new()
	
	#var t = Thread.new()
	ResourceLoader.load_threaded_request(File)
	
	#t.start(LoadSceneTh.bind(Sign, File))
	call_deferred("CheckForFinishedLoad", Sign, File)
	
	$CanvasLayer.visible = true
	set_physics_process(true)
	
	return Sign

func CheckForFinishedLoad(Sign : SignalObject, File : String) -> void:
	var Status = ResourceLoader.load_threaded_get_status(File)
	if (Status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED):
		LoadFinished(Sign, ResourceLoader.load_threaded_get(File))
	else:
		CallLater(CheckForFinishedLoad.bind(Sign, File), 0.1)

func LoadFinished(Sign : SignalObject, File : PackedScene) -> void:
	Sign.Sign.emit(File)
	$CanvasLayer.visible = false
	set_physics_process(false)
	
static func GetInstance() -> Helper:
	return Instance

func CallLater(Call : Callable, t : float = 1) -> void:
	await get_tree().create_timer(t).timeout
	Call.call()

func wait(secs : float) -> Signal:
	return get_tree().create_timer(secs).timeout

static func mapvalue(val : float, min : float, max : float) -> float:
	return min + (max - min) * val

func AngleToDirection(angle: float) -> String:
	var directions = ["East", "Southeast",  "South", "Southwest", "West", "Northwest", "North","Northeast"]
	var index = int(fmod((angle + PI/8 + TAU), TAU) / (PI / 4)) % 8
	return directions[index]

static func SmoothLine(L : Array, res : float = 200) -> Array[Vector2]:
	var newline : Array[Vector2]
	for pointIndex in range(0, L.size()-1):
		var currentpoint = L[pointIndex]
		newline.append(currentpoint)
		var nextpoint = L[pointIndex + 1]
		var dist = currentpoint.distance_to(nextpoint)
		var direction = currentpoint.direction_to(nextpoint)
		if (currentpoint.y == nextpoint.y):
			continue
		for g in range(1, dist / res):
			
			var newpoint = currentpoint + (direction * (res * g))
			
			var newdist = abs(currentpoint.y - newpoint.y)
			var ydist = abs(currentpoint.y - nextpoint.y)
			
			var d = newdist / ydist
			var s = smoothstep(currentpoint.y, nextpoint.y, newpoint.y)
			newpoint.y = lerp(currentpoint.y, nextpoint.y, s)
			newline.append(newpoint)
	
	newline.append(L[L.size() - 1])
	
	return newline

static func SmoothLine2(L : Array, res : float = 200) -> Array[Vector2]:
	var newline : Array[Vector2]
	for pointIndex in range(0, L.size()-1):
		var currentpoint = L[pointIndex]
		newline.append(currentpoint)
		var nextpoint = L[pointIndex + 1]
		var dist = currentpoint.distance_to(nextpoint)
		var direction = currentpoint.direction_to(nextpoint)
		if (currentpoint.y == nextpoint.y):
			continue
		for g in range(1, dist / res):
			
			var newpoint = currentpoint + (direction * (res * g))
			
			var newdist = abs(currentpoint.y - newpoint.y)
			var ydist = abs(currentpoint.y - nextpoint.y)
			
			var d = newdist / ydist
			var s = smoothstep(currentpoint.y, nextpoint.y, newpoint.y)
			var s2 = smoothstep(currentpoint.x, nextpoint.x, newpoint.x)
			newpoint.y = lerp(currentpoint.y, nextpoint.y, s)
			newpoint.x = lerp(currentpoint.x, nextpoint.x, s2)
			newline.append(newpoint)
	
	newline.append(L[L.size() - 1])
	
	return newline

func DistanceToDistance(Dist: float) -> String:
	if Dist > 8000:
		return "very far"
	elif Dist > 5000:
		return "far"
	elif Dist > 3000:
		return "close"
	elif Dist > 1000:
		return "fairly close"
	else:
		return "very close"
		
func GetCityByName(CityName : String) -> MapSpot:
	var SpotGroups = ["CAPITAL", "CITY_CENTER", "VILLAGE"]
	var cities = []
	for g in SpotGroups:
		cities.append_array( get_tree().get_nodes_in_group(g))
	var CorrectCity : MapSpot
	for g in cities:
		var cit = g as MapSpot
		if (cit.GetSpotName() == CityName):
			CorrectCity = cit
			break
	return CorrectCity

func GetClosestSpot(Pos : Vector2) -> MapSpot:
	var Closest : MapSpot
	var Dist = 99999999999999
	for g in get_tree().get_nodes_in_group("City"):
		var Dist2 = Pos.distance_to(g.global_position)
		if (Dist2 < Dist):
			Dist = Dist2
			Closest = g
			if (Dist < 200):
				break

	return Closest

func GetSpotsCloserThan(Pos : Vector2, Dist : float) -> Array[MapSpot]:
	var Spots : Array[MapSpot]
	for g in get_tree().get_nodes_in_group("City"):
		var Dist2 = Pos.distance_to(g.global_position)
		if (Dist2 < Dist):
			Spots.append(g)

	return Spots

func GetSpotByName(CityName : String) -> MapSpot:
	var CorrectCity : MapSpot
	for g in get_tree().get_nodes_in_group("City"):
		var cit = g as MapSpot
		if (cit.GetSpotName() == CityName):
			CorrectCity = cit
			break
	return CorrectCity

func FindPath(start_city: String, end_city: String) -> Array:
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
			return reconstruct_path(parent, end_city)
		
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

func reconstruct_path(parent: Dictionary, end_city: String) -> Array:
	var path = []
	var current_city = end_city
	while current_city != null:
		path.append(current_city)
		current_city = parent[current_city]
		
	path.reverse()  # Reverse the path to get it from start to end
	return path

func GetColorForRegion(R : MapSpotCompleteInfo.REGIONS):
	return RegionColors[R]

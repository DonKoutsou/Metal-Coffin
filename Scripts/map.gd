extends Control
class_name Map

@export var Villages : Array[PackedScene]
@export var Cities : Array[PackedScene]
@export var CapitalCity : PackedScene
@export var FinalCity : PackedScene
@export var MapSize : int
@export var MapGenerationDistanceCurve : Curve
@onready var thrust_slider: ThrustSlider = $UI/ScreenUi/ThrustSlider
@onready var camera_2d: ShipCamera = $CanvasLayer/SubViewportContainer/SubViewport/ShipCamera

#signal MAP_AsteroidBeltArrival(Size : int)
signal MAP_EnemyArrival(FriendlyShips : Array[Node2D] , EnemyShips : Array[Node2D])
signal MAP_NeighborsSet
#signal MAP_StageSearched(Spt : MapSpotType)
#signal MAP_ShipSearched(Ship : BaseShip)

var SpotList : Array[Town]
var ShowingTutorial = false

static var Instance : Map

static func GetInstance() -> Map:
	return Instance

func _ready() -> void:
	Instance = self
	# spotlist empty means we are not loading and starting new game
	GetMapMarkerEditor().visible = false
	$UI/MapMarkerControls.visible = false
	if (SpotList.size() == 0):
		GenerateMap()
		_InitialPlayerPlacament()
		ShowingTutorial = true

func _InitialPlayerPlacament():
	#find first village and make sure its visible
	var firstvilage = get_tree().get_nodes_in_group("VILLAGE")[0] as MapSpot
	firstvilage.OnSpotSeen(false)
	#place player close to first village
	var pos = firstvilage.global_position
	pos.y += 500
	var PlShip = GetPlayerShip()
	PlShip.global_position = pos
	camera_2d.global_position = PlShip.global_position
	PlShip.ShipLookAt(firstvilage.global_position)

#Called when enemy ship touches friendly one to strart a fight
func EnemyMet(FriendlyShips : Array[Node2D] , EnemyShips : Array[Node2D]):
	MAP_EnemyArrival.emit(FriendlyShips, EnemyShips)

func ToggleVis(t : bool ):
	visible = t
	$CanvasLayer.visible = t

func ToggleUIForIntro(t : bool):
	PlayerShip.GetInstance().ToggleUI(t)
	$UI/ScreenUi.visible = t

func ToggleMapMarkerPlecement(t : bool) -> void:
	$UI/ScreenUi.visible = !t
	$UI/MapMarkerControls.visible = t
	GetMapMarkerEditor().visible = t

func GetMapMarkerEditor() -> MapMarkerEditor:
	return $CanvasLayer/SubViewportContainer/SubViewport/InScreenUI/Control3/MapMarkerEditor

func GetPlayerPos() -> Vector2:
	return GetPlayerShip().position
func GetPlayerShip() -> PlayerShip:
	return $CanvasLayer/SubViewportContainer/SubViewport/PlayerShip

func RespawnEnemies(EnemyData : Array[Resource]) -> void:
	for g in EnemyData:
		var ship = (load(g.Scene) as PackedScene).instantiate() as HostileShip
		ship.LoadSaveData(g)
		$CanvasLayer/SubViewportContainer/SubViewport.add_child(ship)
		ship.global_position = g.Position
func RespawnMissiles(MissileData : Array[Resource]) -> void:
	for g in MissileData:
		var dat = g as MissileSaveData
		var missile = (load(dat.Scene) as PackedScene).instantiate() as Missile
		missile.Distance = dat.Distance
		missile.MissileName = dat.MisName
		missile.Speed = dat.MisSpeed
		$CanvasLayer/SubViewportContainer/SubViewport.add_child(missile)
		missile.global_position = dat.Pos
		missile.global_rotation = dat.Rot
		
	for g in get_tree().get_nodes_in_group("Enemy"):
		g.connect("OnShipMet", EnemyMet)
func GetEnemySaveData() ->SaveData:
	var dat = SaveData.new()
	dat.DataName = "Enemies"
	var Datas : Array[Resource] = []
	for g in get_tree().get_nodes_in_group("Enemy"):
		var enem = g as HostileShip
		Datas.append(enem.GetSaveData())
	dat.Datas = Datas
	return dat
func GetMissileSaveData() -> SaveData:
	var dat = SaveData.new()
	dat.DataName = "Missiles"
	var Datas : Array[Resource] = []
	for g in get_tree().get_nodes_in_group("Missiles"):
		var mis = g as Missile
		Datas.append(mis.GetSaveData())
	dat.Datas = Datas
	return dat

#CALLED BY WORLD AFTER STAGE IS FINISHED AND WE HAVE REACHED THE NEW PLANET
func Arrival(_Spot : MapSpot)	-> void:
	if (ShowingTutorial):
		SimulationManager.GetInstance().TogglePause(true)
		var DiagText : Array[String] = ["You have reached a place you can land, make sure you stop in time so you can land.", "Landing on different prots allows you to refuel, repair and upgrade you ship and also fine possible recruits"]
		Ingame_UIManager.GetInstance().CallbackDiag(DiagText, LandTutorialShown, false)
	
func LandTutorialShown():
	SimulationManager.GetInstance().TogglePause(false)
	ShowingTutorial = false

func StageFailed() -> void:
	# enable inputs
	set_process(true)
	set_process_input(true)
	#Travelling = false
#Save/Load///////////////////////////////////////////
func GetSaveData() ->SaveData:
	var dat = SaveData.new().duplicate()
	dat.DataName = "Towns"
	var Datas : Array[Resource] = []
	for g in SpotList.size():
		if (SpotList[g] == null):
			continue
		Datas.append(SpotList[g].GetSaveData())
	dat.Datas = Datas
	return dat
func GetMapMarkerEditorSaveData() -> SaveData:
	var dat = SaveData.new().duplicate()
	dat.DataName = "MarkerEditor"
	var EditorData = SD_MapMarkerEditor.new()
	for g in $CanvasLayer/SubViewportContainer/SubViewport/MapPointerManager/Lines.get_children():
		if (g is MapMarkerLine):
			EditorData.AddLine(g)
		else : if (g is MapMarkerText):
			EditorData.AddText(g)
	dat.Datas.append(EditorData)
	return dat
func LoadMapMarkerEditorSaveData(Data : SD_MapMarkerEditor) -> void:
	$CanvasLayer/SubViewportContainer/SubViewport/InScreenUI/Control3/MapMarkerEditor.LoadData(Data)
func LoadSaveData(Data : Array[Resource]) -> void:
	for g in Data.size():
		var dat = Data[g] as TownSaveData
		
		var sc = load(dat.TownScene).instantiate() as Town
		sc.LoadingData = true
		$CanvasLayer/SubViewportContainer/SubViewport/MapSpots.add_child(sc)
		sc.connect("TownSpotAproached", Arrival)
		
		sc.LoadSaveData(dat)
		SpotList.insert(g, sc)
	
	call_deferred("GenerateRoads")
	$CanvasLayer/SubViewportContainer/SubViewport/ShipCamera.call_deferred("FrameCamToPlayer")
#////////////////////////////////////////////	
#SIGNALS COMMING FROM PLAYER SHIP
func ShipStartedMoving():
	camera_2d.applyshake()
func ShipStoppedMoving():
	camera_2d.applyshake()
func OnScreenUiToggled(t : bool) -> void:
	$UI/ScreenUi.visible = t
func ShipForcedStop():
	thrust_slider.ZeroAcceleration()
#INPUT HANDLING////////////////////////////
func _MAP_INPUT(event: InputEvent) -> void:
	if (event.is_action_pressed("ZoomIn")):
		camera_2d._HANDLE_ZOOM(1.1)
	if (event.is_action_pressed("ZoomOut")):
		camera_2d._HANDLE_ZOOM(0.9)
	if (event is InputEventScreenTouch):
		camera_2d._HANDLE_TOUCH(event)
	if (event is InputEventScreenDrag):
		camera_2d._HANDLE_DRAG(event)
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		camera_2d.UpdateCameraPos(event.relative)
#//////////////////////////////////////////////////////////
var Maplt : Thread
var Roadt : Thread
var Mut : Mutex
#MAP GENERARION
func GenerateMap() -> void:
	#DECIDE ON PLECEMENT OF STATIONS
	var CapitalCitySpots : Array[int] = []
	for z in MapSize / 3:
		if (z == 0):
			continue
		CapitalCitySpots.append(z * 6)
		
	var VillageSpots : Array[int] = []
	
	for z in MapSize/10:
		var spot = z * 10
		if (CapitalCitySpots.has(spot)):
			spot += 1
		VillageSpots.append(spot)
	#LOCATION OF PREVIUSLY PLACED MAP SPOT
	var Prevpos : Vector2 = Vector2(250,250)
	
	#var line = $CanvasLayer/SubViewportContainer/SubViewport/MapSpots/StationLine

	for g in MapSize :
		#SPAWN GENERIC MAP SPOT SCENE
		var sc
		
		#CONNECT ALL RELEVANT SIGNALS TO IT
		#var AddingStation = false
		#DECIDE ON TYPE
		var type : PackedScene
		
		if (g == MapSize - 10):
			type = FinalCity
			#AddingStation = true
		else : if (CapitalCitySpots.has(g)):
			type = CapitalCity
		else :if (VillageSpots.has(g)):
			type = Villages.pick_random()
			#AddingStation = true
		else:
			type = Cities.pick_random()
			
		#SET THE TYPE
		sc = type.instantiate() as Town
		sc.connect("TownSpotAproached", Arrival)
		#DECIDE ON ITS PLACEMENT
		var Distanceval = MapGenerationDistanceCurve.sample(g / (MapSize as float))
		#PICK A SPOT BETWEEN THE PREVIUSLY PLACED MAP SPOT AND THE MAX ALLOWED BASED ON THE CURVE
		var pos = GetNextRandomPos(Prevpos, Distanceval)
		#MAKE SURE WE DONT PLACE IT TO CLOSE TO ANOTHER TIME
		#HASCLOSE COULD BE DONE BETTER TO NOT ITTERATE OVER ALL MAP SPOTS PLACED
		while (HasClose(pos)):
			pos = GetNextRandomPos(Prevpos, Distanceval)
		#POSITIONS IT AND ADD IT TO MAP SPOT LIST
		sc.Pos = pos
		$CanvasLayer/SubViewportContainer/SubViewport/MapSpots.add_child(sc)
		
		SpotList.append(sc)
		#MAKE SURE TO SAVE POSITION OF PLACED MAP SPOT FOR NEXT ITERRATION
		Prevpos = pos
	for g in SpotList:
		g.SpawnEnemies()
	for g in get_tree().get_nodes_in_group("Enemy"):
		g.connect("OnShipMet", EnemyMet)
	
	GenerateRoads()
	#_DrawMapLines(["City Center", "Capital City Center"])
	#_DrawMapLines(["City Center", "Capital City Center","Chora"], true, false)
#ROAD GENERATION
func GenerateRoads() -> void:
	var CityGroups = ["CITY_CENTER"]
	var AllSpotGroups = ["CITY_CENTER", "VILLAGE"]
	var Spots : Array
	for g in CityGroups:
		Spots.append_array(get_tree().get_nodes_in_group(g))
	var cityloc : Array[Vector2]
	for g in Spots:
		cityloc.append(g.global_position)
		
	var Spots2 : Array
	for g in AllSpotGroups:
		Spots2.append_array(get_tree().get_nodes_in_group(g))
	var cityloc2 : Array[Vector2]
	for g in Spots2:
		cityloc2.append(g.global_position)
	Mut = Mutex.new()
	Maplt = Thread.new()
	Maplt.start(_DrawMapLines.bind(cityloc, $CanvasLayer/SubViewportContainer/SubViewport/MapLines, true))
	Roadt = Thread.new()
	Roadt.start(_DrawMapLines.bind(cityloc2, $CanvasLayer/SubViewportContainer/SubViewport/Roads, false, true, false))
func GeneratePathsFromLines(Lines : Array):
	var Cits = get_tree().get_nodes_in_group("CITY_CENTER")
	for g in Cits:
		var SpotPos = g.global_position
		var Neighbors : Array[String] = []
		for Line in Lines:
			if (Line.has(SpotPos)):
				for v in Cits:
					if (v == g):
						continue
					if (Neighbors.has(v)):
						continue
					var SpotPos2 = v.global_position
					if (Line.has(SpotPos2)):
						Neighbors.append(v.SpotInfo.SpotName)
						break
		g.SetNeighbord(Neighbors)
	MAP_NeighborsSet.emit()
	#print(find_path("Amarta", "Blanst"))
	#print(find_path("Tsard", "Witra"))
func _DrawMapLines(SpotLocs : Array, PlacementNode : Node2D, GenerateNeighbors : bool, RandomiseLines : bool = false, Unshaded : bool = true) -> void:
	var time = Time.get_ticks_msec()
	var lines = _prim_mst_optimized(SpotLocs)
	if (GenerateNeighbors):
		call_deferred("GeneratePathsFromLines", lines)
	print("Figuring out lines took " + var_to_str(Time.get_ticks_msec() - time) + " msec")
	var mat = CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	var paintedlines : Array[Line2D]
	for l in lines:
		var lne = Line2D.new()
		lne.width = 20
		lne.joint_mode = Line2D.LINE_JOINT_ROUND
		paintedlines.append(lne)
		#lne.default_color = Color(1,1,1,0.2)
		if (Unshaded):
			lne.material = mat
		PlacementNode.call_deferred("add_child", lne)
		for g in l:
			lne.add_point(g)
		if (Unshaded):
			lne.z_index = 2
	if (!RandomiseLines):
		return 
	for l in paintedlines:
		var point1 = l.get_point_position(0)
		var point2 = l.get_point_position(1)
		l.remove_point(1)
		
		var dir = point1.direction_to(point2)
		
		var dist = point1.distance_to(point2)
		var pointamm = roundi(dist / 50)
		var offsetperpoint = dist/pointamm
		for g in pointamm:
			var offset = (dir * (offsetperpoint * g)) + Vector2(randf_range(-20, 20), randf_range(-20, 20))
			Mut.lock()
			l.add_point(point1 + offset)
			Mut.unlock()
		l.add_point(point2)

	if (RandomiseLines):
		call_deferred("RoadFinished")
	else:
		call_deferred("MapLineFinished")
func AddPointsToLine(Lne : Line2D, Points : Array[Vector2]) -> void:
	for g in Points:
		Lne.add_point(g)
func RoadFinished() -> void:
	Roadt.wait_to_finish()
	Roadt = null
func MapLineFinished() -> void:
	Maplt.wait_to_finish()
	Maplt = null
# Helper function: Push an element to the heap
func _heap_push(heap: Array, element: Array):
	heap.append(element)
	var i = heap.size() - 1
	while i > 0:
		var parent = (i - 1)
		if heap[i][0] >= heap[parent][0]:
			break
		_swap(heap, i, parent)
		i = parent
func _swap(arr: Array, i: int, j: int):
	var tmp = arr[i]
	arr[i] = arr[j]
	arr[j] = tmp
# Helper function: Pop an element from the heap
func _heap_pop(heap: Array) -> Array:
	_swap(heap, 0, heap.size() - 1)
	var result = heap.pop_back()
	var i = 0
	while i < heap.size():
		var left_child = 2 * i + 1
		var right_child = 2 * i + 2

		var smallest = i
		if left_child < heap.size() and heap[left_child][0] < heap[smallest][0]:
			smallest = left_child
		if right_child < heap.size() and heap[right_child][0] < heap[smallest][0]:
			smallest = right_child
		
		if smallest == i:
			break
		_swap(heap, i, smallest)
		i = smallest
	
	return result
func _prim_mst_optimized(cities: Array) -> Array:
	var num_cities = cities.size()
	if num_cities <= 1:
		return []
	
	var connected = PackedInt32Array()
	connected.append(0)  # Start with the first city connected
	
	var edge_min_heap = []
	var mst_edges = []

	# Add all edges from city 0 to the heap
	for i in range(1, num_cities):
		var distance = cities[0].distance_to(cities[i])
		_heap_push(edge_min_heap, [distance, 0, i])

	while connected.size() < num_cities:
		# Pop the smallest edge from the heap
		var min_edge = _heap_pop(edge_min_heap)
		#var dist = min_edge[0]
		var u = min_edge[1]
		var v = min_edge[2]

		if not connected.has(v):
			connected.append(v)
			mst_edges.append([cities[u], cities[v]])

			# Add all edges from this newly connected city to the heap
			for j in range(num_cities):
				if not connected.has(j):
					var new_distance = cities[v].distance_to(cities[j])
					_heap_push(edge_min_heap, [new_distance, v, j])

	return mst_edges
func GetNextRandomPos(PrevPos : Vector2, Distance : float) -> Vector2:
	return Vector2(randf_range(-5000, +5000), randf_range(PrevPos.y, PrevPos.y - (200 * Distance)))
#TODO IMPROVE
func HasClose(pos : Vector2) -> bool:
	var b= false
	for z in SpotList.size():
		if (pos.distance_to(SpotList[z].position) < 800):
			b = true
			break
	return b	
func _exit_tree() -> void:
	if (Roadt != null):
		Roadt.wait_to_finish()
	if (Maplt != null):
		Maplt.wait_to_finish()
#//////////////////////////////////////////////////////////
#SIMULTATION
var simmulationPaused = false

func _on_simulation_button_pressed() -> void:
	simmulationPaused = !SimulationManager.GetInstance().Paused
	SimulationManager.GetInstance().TogglePause(simmulationPaused)

func _on_speed_simulation_button_down() -> void:
	SimulationManager.GetInstance().SpeedToggle(true)

func _on_speed_simulation_button_up() -> void:
	SimulationManager.GetInstance().SpeedToggle(false)

func _on_missile_button_pressed() -> void:
	PlayerShip.GetInstance().FireMissile()

func _on_marker_plecement_pressed() -> void:
	ToggleMapMarkerPlecement(true)

func _on_exit_map_marker_pressed() -> void:
	ToggleMapMarkerPlecement(false)

func _on_clear_lines_pressed() -> void:
	for g in $CanvasLayer/SubViewportContainer/SubViewport/MapPointerManager/Lines.get_children():
		g.queue_free()

extends CanvasLayer
class_name Map
@export_group("Nodes")
@export var _InScreenUI : Ingame_UIManager
@export var _ScreenUI : ScreenUI
@export var _Camera : ShipCamera
#@export var _StatPanel : StatPanel
@export_group("Map Generation")
@export var Villages : Array[PackedScene]
@export var Cities : Array[PackedScene]
@export var CapitalCity : PackedScene
@export var FinalCity : PackedScene
@export var MapSize : int
@export var MapGenerationDistanceCurve : Curve
@export var EnemyScene : PackedScene
@export var EnSpawner : SpawnDecider
@export var EnemyShipNames : Array[String]

signal MAP_EnemyArrival(FriendlyShips : Array[Node2D] , EnemyShips : Array[Node2D])
signal MAP_NeighborsSet
signal GenerationFinished

var TempEnemyNames: Array[String]
var SpotList : Array[Town]
var ShowingTutorial = false

static var Instance : Map

static func GetInstance() -> Map:
	return Instance

func _ready() -> void:
	set_physics_process(false)
	Instance = self
	# spotlist empty means we are not loading and starting new game
	#GetMapMarkerEditor().visible = false
	#MapMarkerControls.visible = false
	#call_deferred("Init")
	#ConnectMapMarkerEditorControls()
	


func _InitialPlayerPlacament():
	#find first village and make sure its visible
	var firstvilage = get_tree().get_nodes_in_group("VILLAGE")[0] as MapSpot
	firstvilage.OnSpotSeen(false)
	#place player close to first village
	var pos = firstvilage.global_position
	pos.y += 500
	var PlShip = $SubViewportContainer/ViewPort/PlayerShip
	PlShip.global_position = pos
	GetCamera().global_position = PlShip.global_position
	PlShip.ShipLookAt(firstvilage.global_position)

#Called when enemy ship touches friendly one to strart a fight
func EnemyMet(FriendlyShips : Array[Node2D] , EnemyShips : Array[Node2D]):
	MAP_EnemyArrival.emit(FriendlyShips, EnemyShips)

func ScreenControls(t : bool) -> void:
	$OuterUI/ButtonCover.visible = !t



func GetMapMarkerEditor() -> MapMarkerEditor:
	return GetInScreenUI().GetMapMarkerEditor()
func GetInScreenUI() -> Ingame_UIManager:
	return _InScreenUI

#func GetElintUI() -> ElingUI:
	#return Elint
func GetScreenUi() -> ScreenUI:
	return _ScreenUI
func GetCamera() -> ShipCamera:
	return _Camera
#func GetStatUI() -> StatPanel:
	#return _StatPanel


#CALLED BY WORLD AFTER STAGE IS FINISHED AND WE HAVE REACHED THE NEW PLANET
func Arrival(_Spot : MapSpot) -> void:
	if (ShowingTutorial):
		SimulationManager.GetInstance().TogglePause(true)
		var DiagText : Array[String] = ["You have reached a place you can land, make sure you stop in time so you can land.", "Landing on different prots allows you to refuel, repair and upgrade you ship and also fine possible recruits"]
		Ingame_UIManager.GetInstance().CallbackDiag(DiagText, load("res://Assets/artificial-hive.png"), LandTutorialShown, false)
	
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
	for g in $SubViewportContainer/ViewPort/MapPointerManager/MapLines.get_children():
		if (g is MapMarkerLine):
			EditorData.AddLine(g)
		else : if (g is MapMarkerText):
			EditorData.AddText(g)
	dat.Datas.append(EditorData)
	return dat

func LoadMapMarkerEditorSaveData(Data : SD_MapMarkerEditor) -> void:
	GetMapMarkerEditor().LoadData(Data)

func LoadSaveData(Data : Array[Resource]) -> void:
	for g in Data.size():
		var dat = Data[g] as TownSaveData
		
		var sc = load(dat.TownScenePath).instantiate() as Town
		sc.LoadingData = true
		$SubViewportContainer/ViewPort/MapSpots.add_child(sc)
		sc.connect("TownSpotAproached", Arrival)
		
		sc.LoadSaveData(dat)
		SpotList.insert(g, sc)
	
	#call_deferred("GenerateRoads")
	GetCamera().call_deferred("FrameCamToPlayer")
#////////////////////////////////////////////	
#SIGNALS COMMING FROM PLAYER SHIP

func ShipStartedMoving():
	GetCamera().applyshake()
	
func ShipStoppedMoving():
	GetCamera().applyshake()

#func ShipForcedStop():
	#thrust_slider.ZeroAcceleration()
	
#INPUT HANDLING////////////////////////////
func _MAP_INPUT(event: InputEvent) -> void:
	if (event is InputEventScreenTouch):
		GetCamera()._HANDLE_TOUCH(event)
	else : if (event is InputEventScreenDrag):
		GetCamera()._HANDLE_DRAG(event)
	else : if (event.is_action_pressed("ZoomIn")):
		GetCamera()._HANDLE_ZOOM(1.1)
	else : if (event.is_action_pressed("ZoomOut")):
		GetCamera()._HANDLE_ZOOM(0.9)
	else : if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		GetCamera().UpdateCameraPos(event.relative)
		
		
#//////////////////////////////////////////////////////////
#/////////////////////////////////////////////////////////////
#/////////////////////////////////////////////////////////////
#MAP GENERARION
var GenThread : Thread

func GenerateMap() -> void:
	#if (SpotList.size() == 0):
	GenThread = Thread.new()
	GenThread.start(GenerateMapThreaded.bind($SubViewportContainer/ViewPort/MapSpots))
	#_InitialPlayerPlacament()
	ShowingTutorial = true


func GenerateMapThreaded(SpotParent : Node2D) -> void:
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
	
	var GeneratedSpots : Array[Town] = []
	for g in MapSize :
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
		var sc = type.instantiate() as Town
		sc.connect("TownSpotAproached", Arrival)
		#DECIDE ON ITS PLACEMENT
		var Distanceval = MapGenerationDistanceCurve.sample(g / (MapSize as float))
		#PICK A SPOT BETWEEN THE PREVIUSLY PLACED MAP SPOT AND THE MAX ALLOWED BASED ON THE CURVE
		var pos = GetNextRandomPos(Prevpos, Distanceval)
		#MAKE SURE WE DONT PLACE IT TO CLOSE TO ANOTHER TIME
		#HASCLOSE COULD BE DONE BETTER TO NOT ITTERATE OVER ALL MAP SPOTS PLACED
		while (HasClose(pos, GeneratedSpots)):
			pos = GetNextRandomPos(Prevpos, Distanceval)
		#POSITIONS IT AND ADD IT TO MAP SPOT LIST
		sc.Pos = pos
		SpotParent.call_deferred("add_child", sc)
		sc.call_deferred("SetMerch", EnSpawner.GetMerchForPosition(pos.y))
		GeneratedSpots.append(sc)
		#MAKE SURE TO SAVE POSITION OF PLACED MAP SPOT FOR NEXT ITERRATION
		Prevpos = pos
	
	var time = Time.get_ticks_msec()
	
	call_deferred("MapGenFinished", GeneratedSpots)


func MapGenFinished(Spots : Array[Town]) -> void:
	SpotList.append_array(Spots)
	GenThread.wait_to_finish()
	GenerationFinished.emit()
	
	
#/////////////////////////////////////////////////////////////
#/////////////////////////////////////////////////////////////
#/////////////////////////////////////////////////////////////
#ENEMY SPAWNING
var EnemySpawnTh : Thread

func SpawnTownEnemies() -> void:
	EnSpawner.Init()
	TempEnemyNames.append_array(EnemyShipNames)
	EnemySpawnTh = Thread.new()
	EnemySpawnTh.start(SpawnTownEnemiesThreaded.bind(SpotList))
	
	
func RespawnEnemies(EnemyData : Array[Resource]) -> void:
	EnSpawner.Init()
	TempEnemyNames.append_array(EnemyShipNames)
	EnemySpawnTh = Thread.new()
	EnemySpawnTh.start(RespawnEnemiesThreaded.bind(EnemyData))


func SpawnTownEnemiesThreaded(Towns : Array[Town]) -> void:
	for T in Towns:
		var Spot = T.GetSpot()
		var time = Time.get_ticks_msec()
		if (T.IsEnemy()):
			SpawnSpotFleet(Spot, false, T.Pos)
		if (Spot.GetPossibleDrops().size() == 3):
			SpawnSpotFleet(Spot, true, T.Pos)
		#print("Spawning fleet took " + var_to_str(Time.get_ticks_msec() - time) + " msec")
	call_deferred("EnemySpawnFinished")


func SpawnSpotFleet(Spot : MapSpot, Patrol : bool, Pos : Vector2) -> void:
	var Fleet = EnSpawner.GetSpawnsForLocation(Pos.y)
	var SpawnedFleet = []
	var SpawnedCallsigns = []
	for f in Fleet:
		var Ship = EnemyScene.instantiate() as HostileShip
		Ship.Cpt = f
		Ship.CurrentPort = Spot
		Ship.Patrol = Patrol
		Ship.ShipName = TempEnemyNames.pop_back()
		SpawnedCallsigns.append(f.ShipCallsign)
		SpawnedFleet.append(Ship)
		EnemsToSpawn[Ship] = Pos
		#call_deferred("AddEnemyToHierarchy", Ship, Pos)
		if (Fleet.find(f) != 0):
			Ship.ToggleDocked(true)
			Ship.Command = SpawnedFleet[0]
			SpawnedFleet[0].GetDroneDock().call_deferred("DockShip", Ship)
	#print("A fleet consisting of {0} was spawned at the port of {1}. Patrol = {2}".format([var_to_str(SpawnedCallsigns), Spot.GetSpotName(), Patrol]))

func RespawnEnemiesThreaded(EnemyData : Array[Resource]) -> void:
	var SpawnedEnems : Array[HostileShip] = []
	for g in EnemyData:
		var ship = (load(g.Scene) as PackedScene).instantiate() as HostileShip
		ship.LoadSaveData(g)
		SpawnedEnems.append(ship)
		EnemsToSpawn[ship] = g.Position
		#call_deferred("AddEnemyToHierarchy", ship, g.Position)
		if (g.CommandName != ""):
			var com
			for z in SpawnedEnems:
				if (z.GetShipName() == g.CommandName):
					com = z
			ship.ToggleDocked(true)
			ship.Command = com
			com.GetDroneDock().call_deferred("DockShip", ship)
	call_deferred("EnemySpawnFinished")

var EnemsToSpawn : Dictionary

func _physics_process(delta: float) -> void:
	if (EnemsToSpawn.size() == 0):
		set_physics_process(false)
		GenerationFinished.emit()
		return
	var enem = EnemsToSpawn.keys()[0]
	var pos = EnemsToSpawn[enem]
	EnemsToSpawn.erase(enem)
	AddEnemyToHierarchy(enem, pos)
	return

func AddEnemyToHierarchy(en : HostileShip, pos : Vector2):
	en.PosToSpawn = pos
	$SubViewportContainer/ViewPort.add_child(en)
	en.connect("OnShipMet", EnemyMet)


func FindEnemyByName(Name : String) -> HostileShip:
	for g in get_tree().get_nodes_in_group("Enemy"):
		if (g.GetShipName() == Name):
			return g
	return null


func GetEnemySaveData() ->SaveData:
	var dat = SaveData.new()
	dat.DataName = "Enemies"
	var Datas : Array[Resource] = []
	for g in get_tree().get_nodes_in_group("Enemy"):
		var enem = g as HostileShip
		Datas.append(enem.GetSaveData())
	dat.Datas = Datas
	return dat


func RespawnMissiles(MissileData : Array[Resource]) -> void:
	for g in MissileData:
		var dat = g as MissileSaveData
		var missile = (load(dat.Scene) as PackedScene).instantiate() as Missile
		missile.Distance = dat.Distance
		missile.MissileName = dat.MisName
		missile.Speed = dat.MisSpeed
		$SubViewportContainer/ViewPort.add_child(missile)
		missile.global_position = dat.Pos
		missile.global_rotation = dat.Rot
	for g in get_tree().get_nodes_in_group("Enemy"):
		g.connect("OnShipMet", EnemyMet)


func GetMissileSaveData() -> SaveData:
	var dat = SaveData.new()
	dat.DataName = "Missiles"
	var Datas : Array[Resource] = []
	for g in get_tree().get_nodes_in_group("Missiles"):
		var mis = g as Missile
		Datas.append(mis.GetSaveData())
	dat.Datas = Datas
	return dat


func EnemySpawnFinished() -> void:
	EnemySpawnTh.wait_to_finish()
	set_physics_process(true)
	
	GenerationFinished.emit()
	
#/////////////////////////////////////////////////////////////
#/////////////////////////////////////////////////////////////
#/////////////////////////////////////////////////////////////
#ROAD GENERATION
var Maplt : Thread
var Roadt : Thread
var Mut : Mutex

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
	Maplt.start(_DrawMapLines.bind(cityloc, true))
	Roadt = Thread.new()
	Roadt.start(_DrawMapLines.bind(cityloc2, false, true))
	
	
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
					if (Neighbors.has(v.SpotInfo.SpotName)):
						continue
					var SpotPos2 = v.global_position
					if (Line.has(SpotPos2)):
						Neighbors.append(v.SpotInfo.SpotName)
						break
		g.SetNeighbord(Neighbors)
	MAP_NeighborsSet.emit()
	#print(find_path("Amarta", "Blanst"))
	#print(find_path("Tsard", "Witra"))
	
	
func _DrawMapLines(SpotLocs : Array, GenerateNeighbors : bool, RandomiseLines : bool = false) -> Array:
	var time = Time.get_ticks_msec()
	var lines = _prim_mst_optimized(SpotLocs)
	if (GenerateNeighbors):
		call_deferred("GeneratePathsFromLines", lines)
	print("Figuring out lines took " + var_to_str(Time.get_ticks_msec() - time) + " msec")
			
	if (RandomiseLines):
		for l in lines:
			var Line = l as Array
			var point1 = Line[0]
			var point2 = Line[1]
			Line.remove_at(1)
			#l.remove_point(1)
			
			var dir = point1.direction_to(point2)
			
			var dist = point1.distance_to(point2)
			var pointamm = roundi(dist / 50)
			var offsetperpoint = dist/pointamm
			for g in pointamm:
				var offs = (dir * (offsetperpoint * g)) + Vector2(randf_range(-20, 20), randf_range(-20, 20))
				Mut.lock()
				Line.append(point1 + offs)
				Mut.unlock()
			Line.append(point2)
			
		call_deferred("RoadFinished")
	else:
		call_deferred("MapLineFinished")
		
	return lines
	
	
func AddPointsToLine(Lne : Line2D, Points : Array[Vector2]) -> void:
	for g in Points:
		Lne.add_point(g)
		
		
func RoadFinished() -> void:
	var Lines = Roadt.wait_to_finish()
	$SubViewportContainer/ViewPort/RoadLineDrawer.AddLines(Lines)
	Roadt = null
	GenerationFinished.emit()
	
	
func MapLineFinished() -> void:
	var Lines = Maplt.wait_to_finish()
	for g in Lines:
		var l = g as Array[Vector2]
		g[0] += (l[0].direction_to(l[1]) * 45)
		g[1] += (l[1].direction_to(l[0]) * 45)
	$SubViewportContainer/ViewPort/MapPointerManager/MapLineDrawer.AddLines(Lines)
	Maplt = null
	GenerationFinished.emit()
	
	
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
	
	
#//////////////////////////////////////////////////////////
#/////////////////////////////////////////////////////////////
#/////////////////////////////////////////////////////////////
func GetNextRandomPos(PrevPos : Vector2, Distance : float) -> Vector2:
	return Vector2(randf_range(-5000, +5000), randf_range(PrevPos.y, PrevPos.y - (200 * Distance)))
#TODO IMPROVE
func HasClose(pos : Vector2, places : Array[Town]) -> bool:
	var b= false
	for z in places.size():
		if (pos.distance_to(places[z].Pos) < 1500):
			b = true
			break
	return b	
func _exit_tree() -> void:
	if (Roadt != null):
		Roadt.wait_to_finish()
	if (Maplt != null):
		Maplt.wait_to_finish()

#func _on_captain_button_pressed() -> void:
	#GetInScreenUI().GetCapUI()._on_captain_button_pressed()

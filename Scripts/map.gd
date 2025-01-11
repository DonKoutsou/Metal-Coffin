extends CanvasLayer
class_name Map

@export var Villages : Array[PackedScene]
@export var Cities : Array[PackedScene]
@export var CapitalCity : PackedScene
@export var FinalCity : PackedScene
@export var MapSize : int
@export var MapGenerationDistanceCurve : Curve
@export var EnemyScene : PackedScene
@onready var thrust_slider: ThrustSlider = $OuterUI/ThrustSlider


signal MAP_EnemyArrival(FriendlyShips : Array[Node2D] , EnemyShips : Array[Node2D])
signal MAP_NeighborsSet

var SpotList : Array[Town]
var ShowingTutorial = false

static var Instance : Map

static func GetInstance() -> Map:
	return Instance

func _ready() -> void:
	Instance = self
	$SubViewportContainer/ViewPort/InScreenUI/Control3/UnderStatUI/InventoryUI.connect("OnUiToggled", OnScreenUiToggled)
	# spotlist empty means we are not loading and starting new game
	GetMapMarkerEditor().visible = false
	$OuterUI/MapMarkerControls.visible = false
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
	GetCamera().global_position = PlShip.global_position
	PlShip.ShipLookAt(firstvilage.global_position)

#Called when enemy ship touches friendly one to strart a fight
func EnemyMet(FriendlyShips : Array[Node2D] , EnemyShips : Array[Node2D]):
	MAP_EnemyArrival.emit(FriendlyShips, EnemyShips)

func ToggleUIForIntro(t : bool):
	#PlayerShip.GetInstance().ToggleUI(t)
	$OuterUI/ScreenUi.visible = t

func ToggleMapMarkerPlecement(t : bool) -> void:
	$OuterUI/ScreenUi.visible = !t
	$OuterUI/MapMarkerControls.visible = t
	GetMapMarkerEditor().visible = t
func ToggleMapMarkerPlacementAuto() -> void:
	var t = !GetMapMarkerEditor().visible
	$OuterUI/ScreenUi.visible = !t
	$OuterUI/MapMarkerControls.visible = t
	GetMapMarkerEditor().visible = t

func GetMapMarkerEditor() -> MapMarkerEditor:
	return $SubViewportContainer/ViewPort/InScreenUI/Control3/MapMarkerEditor
func GetPlayerPos() -> Vector2:
	return GetPlayerShip().position
func GetPlayerShip() -> PlayerShip:
	return $SubViewportContainer/ViewPort/PlayerShip
func GetCommander() -> Commander:
	return $"../Commander"
func GetCamera() -> ShipCamera:
	return $SubViewportContainer/ViewPort/ShipCamera
func RespawnEnemies(EnemyData : Array[Resource]) -> void:
	for g in EnemyData:
		var ship = (load(g.Scene) as PackedScene).instantiate() as HostileShip
		ship.LoadSaveData(g)
		if (g.CommandName != ""):
			var com = FindEnemyByName(g.CommandName)
			ship.ToggleDocked(true)
			ship.Command = com
			com.GetDroneDock().call_deferred("DockShip", ship)
		$SubViewportContainer/ViewPort.add_child(ship)
		ship.global_position = g.Position

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
	for g in $SubViewportContainer/ViewPort/MapPointerManager/MapLines.get_children():
		if (g is MapMarkerLine):
			EditorData.AddLine(g)
		else : if (g is MapMarkerText):
			EditorData.AddText(g)
	dat.Datas.append(EditorData)
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
	
	call_deferred("GenerateRoads")
	#call_deferred("accept_event")
	#call_deferred(accept_event())
	GetCamera().call_deferred("FrameCamToPlayer")
#////////////////////////////////////////////	
#SIGNALS COMMING FROM PLAYER SHIP
func ShipStartedMoving():
	GetCamera().applyshake()
func ShipStoppedMoving():
	GetCamera().applyshake()
func OnScreenUiToggled(t : bool) -> void:
	$OuterUI/ScreenUi.visible = t
func ShipForcedStop():
	thrust_slider.ZeroAcceleration()
#INPUT HANDLING////////////////////////////
func _MAP_INPUT(event: InputEvent) -> void:
	if (event.is_action_pressed("ZoomIn")):
		GetCamera()._HANDLE_ZOOM(1.1)
	if (event.is_action_pressed("ZoomOut")):
		GetCamera()._HANDLE_ZOOM(0.9)
	if (event is InputEventScreenTouch):
		GetCamera()._HANDLE_TOUCH(event)
	if (event is InputEventScreenDrag):
		GetCamera()._HANDLE_DRAG(event)
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		GetCamera().UpdateCameraPos(event.relative)
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
		while (HasClose(pos)):
			pos = GetNextRandomPos(Prevpos, Distanceval)
		#POSITIONS IT AND ADD IT TO MAP SPOT LIST
		sc.Pos = pos
		$SubViewportContainer/ViewPort/MapSpots.add_child(sc)
		
		SpotList.append(sc)
		#MAKE SURE TO SAVE POSITION OF PLACED MAP SPOT FOR NEXT ITERRATION
		Prevpos = pos
	for g in SpotList:
		SpawnTownEnemies(g)
	for g in get_tree().get_nodes_in_group("Enemy"):
		g.connect("OnShipMet", EnemyMet)
	
	GenerateRoads()
	#_DrawMapLines(["City Center", "Capital City Center"])
	#_DrawMapLines(["City Center", "Capital City Center","Chora"], true, false)
func SpawnTownEnemies(T : Town) -> void:
	var Spots = T.GetSpots()
	for g in Spots:
		var PatrolBP = g.SpotInfo.HostilePatrol
		var PatrolCommander : HostileShip
		for Patrol in PatrolBP.size():
			var Ship = EnemyScene.instantiate() as HostileShip
			var Cpt = Captain.new()
			Cpt.CopyStats(PatrolBP[Patrol])
			Ship.Cpt = Cpt
			Ship.CurrentPort = g
			Ship.ShipName = g.SpotInfo.HostilePatrolShipNames[Patrol]
			Ship.Patrol = true
			if (PatrolCommander == null):
				PatrolCommander = Ship
			else:
				Ship.ToggleDocked(true)
				Ship.Command = PatrolCommander
				PatrolCommander.GetDroneDock().call_deferred("DockShip", Ship)
			$SubViewportContainer/ViewPort.add_child(Ship)
			Ship.global_position = g.global_position
			
		var GarrissonBP = g.SpotInfo.HostileGarrisson
		var GarrissonCommander : HostileShip
		for Garrisson in GarrissonBP.size():
			var Ship = EnemyScene.instantiate() as HostileShip
			var Cpt = Captain.new()
			Cpt.CopyStats(GarrissonBP[Garrisson])
			Ship.Cpt = Cpt
			Ship.CurrentPort = g
			Ship.ShipName = g.SpotInfo.HostileGarrissonShipNames[Garrisson]
			Ship.Patrol = false
			if (GarrissonCommander == null):
				GarrissonCommander = Ship
			else:
				Ship.ToggleDocked(true)
				Ship.Command = GarrissonCommander
				GarrissonCommander.GetDroneDock().call_deferred("DockShip", Ship)
			$SubViewportContainer/ViewPort.add_child(Ship)
			Ship.global_position = g.global_position
			
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
func MapLineFinished() -> void:
	var Lines = Maplt.wait_to_finish()
	$SubViewportContainer/ViewPort/MapPointerManager/MapLineDrawer.AddLines(Lines)
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
	GetPlayerShip().FireMissile()

func _on_marker_plecement_pressed() -> void:
	ToggleMapMarkerPlacementAuto()

func _on_exit_map_marker_pressed() -> void:
	ToggleMapMarkerPlecement(false)

func _on_clear_lines_pressed() -> void:
	for g in $SubViewportContainer/ViewPort/MapPointerManager/MapLines.get_children():
		g.queue_free()

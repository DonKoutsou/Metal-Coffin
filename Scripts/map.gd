extends Control
class_name Map

@export var TownTypes : Array[PackedScene]
@export var SpecialTownTypes : Array[PackedScene]
@export var MinorCityType : PackedScene
@export var FinalCity : PackedScene
@export var MapSize : int = 20
@export var MapGenerationDistanceCurve : Curve
@onready var thrust_slider: ThrustSlider = $UI/ThrustSlider
@onready var camera_2d: ShipCamera = $CanvasLayer/SubViewportContainer/SubViewport/ShipCamera

#signal MAP_AsteroidBeltArrival(Size : int)
signal MAP_EnemyArrival(FriendlyShips : Array[Node2D] , EnemyShips : Array[Node2D])
signal MAP_StageSearched(Spt : MapSpotType)
signal MAP_ShipSearched(Ship : BaseShip)

var SpotList : Array[Town]
var ShowingTutorial = false

func _ready() -> void:
	$CanvasLayer/SubViewportContainer/SubViewport/MapSpots.position = Vector2(0, get_viewport_rect().size.y / 2)
	if (SpotList.size() == 0):
		GenerateMap()
		_InitialPlayerPlacament()
		#call_deferred("")
		ShowingTutorial = true
	var shipdata = ShipData.GetInstance()
	GetPlayerShip().UpdateFuelRange(shipdata.GetStat("FUEL").GetCurrentValue(), shipdata.GetStat("FUEL_EFFICIENCY").GetStat())
	GetPlayerShip().UpdateVizRange(shipdata.GetStat("VIZ_RANGE").GetStat())
	GetPlayerShip().UpdateAnalyzerRange(shipdata.GetStat("ANALYZE_RANGE").GetStat())
	
	#GalaxyMat = $CanvasLayer/SubViewportContainer/SubViewport/Control/ColorRect.material
func _InitialPlayerPlacament():
	var firstvilage = get_tree().get_nodes_in_group("Chora")[0] as MapSpot
	firstvilage.OnSpotSeen(false)
	firstvilage.OnSpotAnalyzed(false)
	var pos = firstvilage.global_position
	pos.x -= 500
	GetPlayerShip().global_position = pos
	camera_2d.global_position = GetPlayerShip().global_position
func GetPlayerPos() -> Vector2:
	return GetPlayerShip().position
func GetPlayerShip() -> PlayerShip:
	return $CanvasLayer/SubViewportContainer/SubViewport/PlayerShip
func EnemyMet(FriendlyShips : Array[Node2D] , EnemyShips : Array[Node2D]):
	MAP_EnemyArrival.emit(FriendlyShips, EnemyShips)
func SetPlayerPos(pos : Vector2) -> void:
	GetPlayerShip().position = pos
	
func ToggleVis(t : bool ):
	visible = t
	$CanvasLayer.visible = t

func PlayIntroFadeInt():
	$AnimationPlayer.play("FadeIn")
	camera_2d.global_position = GetPlayerShip().global_position
	
func ToggleUIForIntro(t : bool):
	GetPlayerShip().ToggleUI(t)
	$UI/ThrustSlider.visible = t
	$UI/SteeringWheel.visible = t
	$CanvasLayer/SubViewportContainer/SubViewport/ShipCamera/ArrowSprite/ArrowSprite2.visible = t
	$UI/RadarButton.visible = t
	$UI/DroneTab.visible = t
	$"UI/Missile Tab".visible = t
	$UI/SimulationButton.visible = t

func GenerateMap() -> void:
	#DECIDE ON PLECEMENT OF SPECIAL SPOTS
	var SpecialSpots : Array[int] = []
	for z in SpecialTownTypes.size():
		SpecialSpots.append(randi_range(5, MapSize - 1))
	#DECIDE ON PLECEMENT OF STATIONS
	var StationSpots : Array[int] = []
	for z in MapSize / 10:
		StationSpots.append(10 * z)
		
	#LOCATION OF PREVIUSLY PLACED MAP SPOT
	var Prevpos : Vector2 = Vector2(250,250)
	
	#var line = $CanvasLayer/SubViewportContainer/SubViewport/MapSpots/StationLine
	
	#SPAWN ON SPOT AND 1 ASTEROID FIELD FOR EACH VALUE OF MAPSIZE
	for g in MapSize :
		#SPAWN GENERIC MAP SPOT SCENE
		var sc
		
		#CONNECT ALL RELEVANT SIGNALS TO IT
		#var AddingStation = false
		#DECIDE ON TYPE
		var type : PackedScene
		
		if (g == MapSize - 1):
			type = FinalCity
			#AddingStation = true
		else :if (SpecialSpots.has(g)):
			type = SpecialTownTypes[SpecialSpots.find(g)]
		else : if (StationSpots.has(g)):
			type = MinorCityType
			#AddingStation = true
		else:
			type = TownTypes.pick_random()
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
	
	_DrawMapLines(["City Center", "Capital City Center"])
	_DrawMapLines(["Chora"], true, false)

func RespawnEnemies(EnemyData : Array[Resource]) -> void:
	for g in EnemyData:
		var ship = (load(g.Scene) as PackedScene).instantiate() as HostileShip
		$CanvasLayer/SubViewportContainer/SubViewport.add_child(ship)
		ship.LoadSaveData(g)
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
func _swap(arr: Array, i: int, j: int):
	var tmp = arr[i]
	arr[i] = arr[j]
	arr[j] = tmp

func GetNextRandomPos(PrevPos : Vector2, Distance : float) -> Vector2:
	return Vector2(randf_range(PrevPos.x, PrevPos.x + (800 * Distance)), randf_range(-2000, +2000))
#TODO IMPROVE
func HasClose(pos : Vector2) -> bool:
	var b= false
	for z in SpotList.size():
		if (pos.distance_to(SpotList[z].position) < 800):
			b = true
			break
	return b	

		#GetPlayerShip().HaltShip()
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

func SearchLocation(stage : MapSpot):
	if (GetPlayerShip().Travelling):
		PopUpManager.GetInstance().DoFadeNotif("Stop the ship to land.")
		return
	#stage.ToggleLandButton(false)
	if (stage.SpotType is Ship_MapSpotType):
		MAP_ShipSearched.emit(stage.SpotType.Ship)
	else:
		MAP_StageSearched.emit(stage)
	

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
func LoadSaveData(Data : Array[Resource]) -> void:
	for g in Data.size():
		var dat = Data[g] as TownSaveData
		
		var sc = load(dat.TownScene).instantiate() as Town
		sc.LoadingData = true
		$CanvasLayer/SubViewportContainer/SubViewport/MapSpots.add_child(sc)
		sc.connect("TownSpotAproached", Arrival)
		
		sc.LoadSaveData(dat)
		SpotList.insert(g, sc)


	call_deferred("_DrawMapLines", ["City Center", "Capital City Center"])
	call_deferred("_DrawMapLines", ["Chora"], true, false)
	$CanvasLayer/SubViewportContainer/SubViewport/ShipCamera.call_deferred("FrameCamToPlayer")

#////////////////////////////////////////////	
#SIGNALS COMMING FROM PLAYER SHIP
func ShipStartedMoving():
	camera_2d.applyshake()
	
func ShipStoppedMoving():
	camera_2d.applyshake()
	
func ShipForcedStop():
	thrust_slider.ZeroAcceleration()
#INPUT HANDLING////////////////////////////
func _MAP_INPUT(event: InputEvent) -> void:
	if (event.is_action_pressed("ZoomIn")):
		camera_2d._HANDLE_ZOOM(1.1)
	if (event.is_action_pressed("ZoomOut")):
		camera_2d._HANDLE_ZOOM(0.9)
	#if (GetPlayerShip().ChangingCourse):
		#return
	if (event is InputEventScreenTouch):
		camera_2d._HANDLE_TOUCH(event)
	if (event is InputEventScreenDrag):
		camera_2d._HANDLE_DRAG(event)
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		camera_2d.UpdateCameraPos(event.relative)

	#print("Zoom changed to " + var_to_str(camera_2d.zoom.x))
#//////////////////////////////////////////////////////////
#ARROW FOR LOCATING PLAYER SHIP
func _process(_delta: float) -> void:
	#var plpos = GetPlayerShip().global_position
	#$CanvasLayer/SubViewportContainer/SubViewport/MapPointers/Panel.global_position = plpos
	$CanvasLayer/SubViewportContainer/SubViewport/ShipCamera/ArrowSprite.look_at(GetPlayerShip().global_position)
func PlayerEnteredScreen() -> void:
	#set_process(false)
	$CanvasLayer/SubViewportContainer/SubViewport/ShipCamera/ArrowSprite.visible = false
func PlayerExitedScreen() -> void:
	#set_process(true)
	$CanvasLayer/SubViewportContainer/SubViewport/ShipCamera/ArrowSprite.visible = true
#//////////////////////////////////////////////////////////

func _DrawMapLines(SpotNames : Array, RandomiseLines : bool = false, Unshaded : bool = true) -> void:
	var Spots : Array
	for g in SpotNames:
		Spots.append_array(get_tree().get_nodes_in_group(g))
	var cityloc : Array[Vector2]
	for g in Spots:
		cityloc.append(g.global_position)
	
	var lines = _prim_mst_optimized(cityloc)
	var mat = CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	var paintedlines : Array[Line2D]
	for l in lines:
		var lne = Line2D.new()
		lne.joint_mode = Line2D.LINE_JOINT_ROUND
		paintedlines.append(lne)
		#lne.default_color = Color(1,1,1,0.2)
		if (Unshaded):
			lne.material = mat
		$CanvasLayer/SubViewportContainer/SubViewport/MapLines.add_child(lne)
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
			l.add_point(point1 + offset)
		
		l.add_point(point2)
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

func _on_missile_button_pressed() -> void:
	GetPlayerShip().FireMissile()

var simmulationPaused = false

func _on_simulation_button_pressed() -> void:
	simmulationPaused = !simmulationPaused
	SimulationManager.GetInstance().TogglePause(simmulationPaused)

func _on_speed_simulation_button_down() -> void:
	SimulationManager.GetInstance().SpeedToggle(true)

func _on_speed_simulation_button_up() -> void:
	SimulationManager.GetInstance().SpeedToggle(false)

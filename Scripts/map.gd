extends Control
class_name Map

#@export var SpotScene: PackedScene
@export var TownTypes : Array[PackedScene]
#@export var MapSpotTypes : Array[MapSpotType]
@export var SpecialTownTypes : Array[PackedScene]
#@export var CommetMapSpots : Array[MapSpotType]
@export var MinorCityType : PackedScene
@export var FinalCity : PackedScene
@export var MapSize : int = 20
#@export var AnalyzerScene : PackedScene
@export var MapGenerationDistanceCurve : Curve

@export var DroneDockEventH : DroneDockEventHandler

@export var HappeningUI : PackedScene

@onready var thrust_slider: ThrustSlider = $UI/ThrustSlider
@onready var camera_2d: ShipCamera = $CanvasLayer/SubViewportContainer/SubViewport/ShipCamera

signal MAP_AsteroidBeltArrival(Size : int)
signal MAP_EnemyArrival(FriendlyShips : Array[Node2D] , EnemyShips : Array[Node2D])
signal MAP_StageSearched(Spt : MapSpotType)
signal MAP_ShipSearched(Ship : BaseShip)

var SpotList : Array[Town]
var currentstage = 0
#var GalaxyMat :ShaderMaterial

func _ready() -> void:
	$CanvasLayer/SubViewportContainer/SubViewport/MapSpots.position = Vector2(0, get_viewport_rect().size.y / 2)
	if (SpotList.size() == 0):
		GenerateMap()
	var shipdata = ShipData.GetInstance()
	GetPlayerShip().UpdateFuelRange(shipdata.GetStat("FUEL").GetCurrentValue(), shipdata.GetStat("FUEL_EFFICIENCY").GetStat())
	GetPlayerShip().UpdateVizRange(shipdata.GetStat("VIZ_RANGE").GetStat())
	GetPlayerShip().UpdateAnalyzerRange(shipdata.GetStat("ANALYZE_RANGE").GetStat())
	#GalaxyMat = $CanvasLayer/SubViewportContainer/SubViewport/Control/ColorRect.material

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
	$ThrustSlider.visible = t
	$SteeringWheel.visible = t
	$CanvasLayer/SubViewportContainer/SubViewport/ShipCamera/ArrowSprite/ArrowSprite2.visible = t
func ShowStation():
	var tw = create_tween()
	var stations = get_tree().get_nodes_in_group("Capital City Center")
	var stationpos = stations[stations.size()-1].global_position
	tw.set_trans(Tween.TRANS_EXPO)
	tw.tween_property(camera_2d, "global_position", stationpos, 6)
	#var mattw = create_tween()
	#mattw.set_trans(Tween.TRANS_EXPO)
	#mattw.tween_property(GalaxyMat, "shader_parameter/thing", stationpos.x / 1800, 6)
	
func FrameCamToPlayer():
	var tw = create_tween()
	var plpos = GetPlayerShip().global_position
	tw.set_trans(Tween.TRANS_EXPO)
	tw.tween_property(camera_2d, "global_position", plpos,6)
	#var mattw = create_tween()
	#mattw.set_trans(Tween.TRANS_EXPO)
	#mattw.tween_property(GalaxyMat, "shader_parameter/thing", plpos.x / 500,6)
func UpdateCameraPos(relativeMovement : Vector2):
	var maxposX = 999999
	var vpsizehalf = (get_viewport_rect().size.y / 2)
	var maxposY = Vector2(vpsizehalf - 2500, vpsizehalf + 2500)
	var rel = relativeMovement / camera_2d.zoom
	var newpos = Vector2(clamp(camera_2d.position.x - rel.x, 0, maxposX), clamp(camera_2d.position.y - rel.y, maxposY.x, maxposY.y))
	if (newpos.x != camera_2d.position.x):
		camera_2d.position.x = newpos.x
		#var val = GalaxyMat.get_shader_parameter("thing")
		#GalaxyMat.set_shader_parameter("thing", val - (rel.x / 1800))
	if (newpos.y != camera_2d.position.y):
		camera_2d.position.y = newpos.y
		#var val2 = GalaxyMat.get_shader_parameter("thing2")
		#GalaxyMat.set_shader_parameter("thing2", val2 - (rel.y / 1800))
		
#func _input(event: InputEvent) -> void:
	#pass

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
		#sc.SetSpotData(type)
		sc = type.instantiate()
		sc.connect("SpotAproached", Arrival)
		sc.connect("SpotSearched", SearchLocation)
		#sc.connect("SpotAnalazyed", AnalyzeLocation)
		$CanvasLayer/SubViewportContainer/SubViewport/MapSpots.add_child(sc)
		#DECIDE ON ITS PLACEMENT
		var Distanceval = MapGenerationDistanceCurve.sample(g / (MapSize as float))
		#PICK A SPOT BETWEEN THE PREVIUSLY PLACED MAP SPOT AND THE MAX ALLOWED BASED ON THE CURVE
		var pos = GetNextRandomPos(Prevpos, Distanceval)
		#MAKE SURE WE DONT PLACE IT TO CLOSE TO ANOTHER TIME
		#HASCLOSE COULD BE DONE BETTER TO NOT ITTERATE OVER ALL MAP SPOTS PLACED
		while (HasClose(pos)):
			pos = GetNextRandomPos(Prevpos, Distanceval)
		#POSITIONS IT AND ADD IT TO MAP SPOT LIST
		sc.position = pos
		SpotList.append(sc)
		#MAKE SURE TO SAVE POSITION OF PLACED MAP SPOT FOR NEXT ITERRATION
		Prevpos = pos
	for g in SpotList:
		g.SpawnEnemies()
	for g in get_tree().get_nodes_in_group("Enemy"):
		g.connect("OnShipMet", EnemyMet)
	_DrawCityLines()
	_DrawVillageLines()
	#print(lines)
		#var cit1 = g as MapSpot
		#var ln = Line2D.new()
		#g.add_child(ln)
		#
		#var mat = CanvasItemMaterial.new()
		#mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		#ln.material = mat
		#
		#ln.add_point(Vector2.ZERO)
		#for z in cities:
			#var cit = z as MapSpot
			#if (z == g):
				#continue
			#if (z.global_position.distance_to(g.global_position) < 4000):
				#ln.add_point(cit1.to_local(cit.global_position))
func RespawnEnemies(EnemyData : Array[Resource]) -> void:
	for g in EnemyData:
		var ship = (load(g.Scene) as PackedScene).instantiate() as HostileShip
		$CanvasLayer/SubViewportContainer/SubViewport.add_child(ship)
		ship.LoadSaveData(g)
func GetEnemySaveData() ->SaveData:
	var dat = SaveData.new()
	dat.DataName = "Enemies"
	var Datas : Array[Resource] = []
	for g in get_tree().get_nodes_in_group("Enemy"):
		var enem = g as HostileShip
		Datas.append(enem.GetSaveData())
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
	
#CALLED BY WORLD AFTER STAGE IS FINISHED AND WE HAVE REACHED THE NEW PLANET
func Arrival(Spot : MapSpot)	-> void:
	if Spot.SpotType.FullName == "Black Whole":
		var randspot = SpotList.pick_random() as MapSpot
		while abs(SpotList.find(randspot) - SpotList.find(Spot)) > 25 or randspot.SpotType.FullName == "Black Whole":
			randspot = SpotList.pick_random() as MapSpot
		GetPlayerShip().global_position = randspot.global_position
		PopUpManager.GetInstance().DoPopUp("You've entered a black whole and have been teleported away")
		GetPlayerShip().HaltShip()
		
	if Spot.SpotType.GetEnumString() == "ASTEROID_BELT":
		Spot.queue_free()
		var val = Spot.SpotType.GetCustomData("IsLarge")[0].Value as bool
		if (val):
			MAP_AsteroidBeltArrival.emit(120)
		else:
			MAP_AsteroidBeltArrival.emit(60)
		GetPlayerShip().HaltShip()
	if (Spot.Evnt != null and !Spot.Visited):
		var happeningui = HappeningUI.instantiate() as HappeningInstance
		Ingame_UIManager.GetInstance().AddUI(happeningui, false, true)
		happeningui.PresentHappening(Spot.Evnt)
		GetPlayerShip().HaltShip()
		
func StageFailed() -> void:
	# enable inputs
	set_process(true)
	set_process_input(true)
	#Travelling = false

		


#func DepartForLocation(stage :MapSpot) -> void:
#	if (Travelling):
#		return
	#var spotprev = SpotList[currentstage] as MapSpot
#	Travelling = true
#	var stagenum = SpotList.find(stage)
#	var fuel = player_ship.global_position.distance_to(stage.global_position) / 10 / ShipData.GetInstance().GetStat("FUEL_EFFICIENCY").GetStat()
#	var o2 = player_ship.global_position.distance_to(stage.global_position) / 40
#	StageSellected.emit(stage, stagenum, fuel, o2)
	# enable inputs
	#set_process(false)
	
# CALLED WHEN CLICKED ON A PLANET
#func AnalyzeLocation(Spot : MapSpot):
	#var analyzer = AnalyzerScene.instantiate() as PlanetAnalyzer
	#analyzer.SetVisuals(Spot)
	#Ingame_UIManager.GetInstance().add_child(analyzer)

func SearchLocation(stage : MapSpot):
	if (GetPlayerShip().Travelling):
		PopUpManager.GetInstance().DoPopUp("Stop the ship to land.")
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
		#sc.connect("MapPressed", Arrival)
		sc.connect("SpotAproached", Arrival)
		sc.connect("SpotSearched", SearchLocation)
		#sc.connect("SpotAnalazyed", AnalyzeLocation)
		#var type = dat.SpotType
		#sc.SetSpotData(type)
		
		sc.LoadSaveData(dat)
		SpotList.insert(g, sc)
		#if (dat.Seen):
			#sc.OnSpotSeen(false)
		#
		#sc.Visited = dat.Visited
		#
		#if (dat.Analyzed):
			#sc.OnSpotAnalyzed()
	call_deferred("_DrawCityLines")
	call_deferred("_DrawVillageLines")
#SCREEN SHAKE///////////////////////////////////
var shakestr = 0.0
func applyshake():
	shakestr = 2

func _physics_process(delta: float) -> void:
	if shakestr > 0.0:
		shakestr = lerpf(shakestr, 0, 5.0 * delta)
		var of = RandomOffset()
		camera_2d.offset = of
func RandomOffset()-> Vector2:
	return Vector2(randf_range(-shakestr, shakestr), randf_range(-shakestr, shakestr))
#////////////////////////////////////////////	
#SIGNALS COMMING FROM PLAYER SHIP
func ShipStartedMoving():
	applyshake()
	
func ShipStoppedMoving():
	applyshake()
	
func ShipForcedStop():
	thrust_slider.ZeroAcceleration()
#INPUT HANDLING////////////////////////////
func _MAP_INPUT(event: InputEvent) -> void:
	if (event.is_action_pressed("ZoomIn")):
		_HANDLE_ZOOM(1.1)
	if (event.is_action_pressed("ZoomOut")):
		_HANDLE_ZOOM(0.9)
	#if (GetPlayerShip().ChangingCourse):
		#return
	if (event is InputEventScreenTouch):
		_HANDLE_TOUCH(event)
	if (event is InputEventScreenDrag):
		_HANDLE_DRAG(event)
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		UpdateCameraPos(event.relative)
#////////////////////////////
func _HANDLE_ZOOM(zoomval : float):
	var prevzoom = camera_2d.zoom
	camera_2d.zoom = clamp(prevzoom * Vector2(zoomval, zoomval), Vector2(0.1,0.1), Vector2(2.1,2.1))
	for g in get_tree().get_nodes_in_group("MapShipVizualiser"):
		g.visible = camera_2d.zoom < Vector2(1, 1)
	for g in get_tree().get_nodes_in_group("MapLines"):
		g.material.set_shader_parameter("line_width", lerp(0.01, 0.001, camera_2d.zoom.x / 2))
	_UpdateMapGridVisibility()
	#for g in get_tree().get_nodes_in_group("DissapearingMap"):
		#g.modulate.a = mod
#////////////////////////////
var touch_points: Dictionary = {}
var start_zoom: Vector2
var start_dist: float
func _HANDLE_TOUCH(event: InputEventScreenTouch):
	if event.pressed:
		touch_points[event.index] = event.position
	else:
		touch_points.erase(event.index)

	if touch_points.size() == 2:
		var touch_point_positions = touch_points.values()
		start_dist = touch_point_positions[0].distance_to(touch_point_positions[1])
		start_zoom = camera_2d.zoom
		#start_dist = 0
#////////////////////////////
func _HANDLE_DRAG(event: InputEventScreenDrag):
	touch_points[event.index] = event.position
	if touch_points.size() == 2 :
		var touch_point_positions = touch_points.values()
		var current_dist = touch_point_positions[0].distance_to(touch_point_positions[1])
		var zoom_factor = (start_dist / current_dist)
		camera_2d.zoom = clamp(start_zoom / zoom_factor, Vector2(0.1,0.1), Vector2(2.1,2.1))
		for g in get_tree().get_nodes_in_group("MapLines"):
			g.material.set_shader_parameter("line_width", lerp(0.01, 0.001, camera_2d.zoom.x / 2))
		_UpdateMapGridVisibility()
	else:
		UpdateCameraPos(event.relative)
		
func _UpdateMapGridVisibility():
	if (camera_2d.zoom.x < 0.25):
		var tw = create_tween()
		tw.tween_property($CanvasLayer/SubViewportContainer/SubViewport/Control2, "modulate", Color(1,1,1,1), 0.5)
	else:
		var tw = create_tween()
		tw.tween_property($CanvasLayer/SubViewportContainer/SubViewport/Control2, "modulate", Color(1,1,1,0), 0.5)
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

#Map Line generation
func _DrawCityLines():
	var cities = get_tree().get_nodes_in_group("City Center")
	cities.append_array(get_tree().get_nodes_in_group("Capital City Center"))
	var cityloc : Array[Vector2]
	for g in cities:
		cityloc.append(g.global_position)
	
	var lines = _prim_mst_optimized(cityloc)
	var mat = CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	#var paintedlines : Array[Line2D]
	for l in lines:
		var lne = Line2D.new()
		lne.joint_mode = Line2D.LINE_JOINT_ROUND
		#paintedlines.append(lne)
		lne.default_color = Color(1,1,1,0.2)
		lne.material = mat
		$CanvasLayer/SubViewportContainer/SubViewport/MapLines.add_child(lne)
		for g in l:
			lne.add_point(g)
		lne.z_index = 2
func _DrawVillageLines():
	var cities = get_tree().get_nodes_in_group("Chora")
	#cities.append_array(get_tree().get_nodes_in_group("Capital City Center"))
	var cityloc : Array[Vector2]
	for g in cities:
		cityloc.append(g.global_position)
	
	var lines = _prim_mst_optimized(cityloc)
	#var mat = CanvasItemMaterial.new()
	#mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	var paintedlines : Array[Line2D]
	for l in lines:
		var lne = Line2D.new()
		lne.width = 5
		lne.joint_mode = Line2D.LINE_JOINT_ROUND
		paintedlines.append(lne)
		lne.default_color = Color(1,1,1,0.3)
		#lne.material = mat
		$CanvasLayer/SubViewportContainer/SubViewport/MapLines.add_child(lne)
		for g in l:
			lne.add_point(g)
		#lne.z_index = 2
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

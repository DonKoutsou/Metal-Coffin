extends Node2D
class_name Map

@export var SpotScene: PackedScene
@export var MapSpotTypes : Array[MapSpotType]
@export var SpecialMapSpotTypes : Array[MapSpotType]
@export var CommetMapSpots : Array[MapSpotType]
@export var MinorStationSpotType : MapSpotType
@export var FinalSpotType : MapSpotType
@export var MapSize : int = 20
@export var AnalyzerScene : PackedScene
@export var MapGenerationDistanceCurve : Curve

@export var DroneDockEventH : DroneDockEventHandler

@onready var thrust_slider: ThrustSlider = $CanvasLayer/UIMaster/ThrustSlider
@onready var camera_2d: Camera2D = $CanvasLayer/UIMaster/SubViewportContainer/SubViewport/Camera2D

signal MAP_AsteroidBeltArrival(Size : int)
signal MAP_StageSearched(Spt : MapSpotType)
signal MAP_ShipSearched(Ship : BaseShip)

var SpotList : Array[MapSpot]
var currentstage = 0
#var GalaxyMat :ShaderMaterial

func _ready() -> void:
	$CanvasLayer/UIMaster/SubViewportContainer/SubViewport/MapSpots.position = Vector2(0, get_viewport_rect().size.y / 2)
	if (SpotList.size() == 0):
		GenerateMap()
	var shipdata = ShipData.GetInstance()
	GetPlayerShip().UpdateFuelRange(shipdata.GetStat("FUEL").GetCurrentValue(), shipdata.GetStat("FUEL_EFFICIENCY").GetStat())
	GetPlayerShip().UpdateVizRange(shipdata.GetStat("VIZ_RANGE").GetStat())
	GetPlayerShip().UpdateAnalyzerRange(shipdata.GetStat("ANALYZE_RANGE").GetStat())
	#GalaxyMat = $CanvasLayer/UIMaster/SubViewportContainer/SubViewport/Control/ColorRect.material



func GetPlayerPos() -> Vector2:
	return GetPlayerShip().position
func GetPlayerShip() -> PlayerShip:
	return $CanvasLayer/UIMaster/SubViewportContainer/SubViewport/MapSpots/PlayerShip

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
	$CanvasLayer/UIMaster/ThrustSlider.visible = t
	$CanvasLayer/UIMaster/SteeringWheel.visible = t
	$CanvasLayer/UIMaster/SubViewportContainer/SubViewport/Camera2D/ArrowSprite/ArrowSprite2.visible = t
func ShowStation():
	var tw = create_tween()
	var stationpos = get_tree().get_nodes_in_group("STATION")[0].global_position
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
	var maxposX = get_tree().get_nodes_in_group("STATION")[0].position.x
	var vpsizehalf = (get_viewport_rect().size.y / 2)
	var maxposY = Vector2(vpsizehalf - 900, vpsizehalf + 900)
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
	for z in SpecialMapSpotTypes.size():
		SpecialSpots.append(randi_range(5, MapSize - 1))
	#DECIDE ON PLECEMENT OF STATIONS
	var StationSpots : Array[int] = []
	for z in MapSize / 10:
		StationSpots.append(10 * z)
		
	#LOCATION OF PREVIUSLY PLACED MAP SPOT
	var Prevpos : Vector2 = Vector2(250,250)
	
	#var line = Line2D.new()
	#$CanvasLayer/SubViewportContainer/SubViewport/MapSpots.add_child(line)
	#$CanvasLayer/SubViewportContainer/SubViewport/MapSpots.move_child(line, 0)
	
	#SPAWN ON SPOT AND 1 ASTEROID FIELD FOR EACH VALUE OF MAPSIZE
	for g in MapSize :
		#SPAWN GENERIC MAP SPOT SCENE
		var sc = SpotScene.instantiate() as MapSpot
		$CanvasLayer/UIMaster/SubViewportContainer/SubViewport/MapSpots/SpotSpot.add_child(sc)
		#CONNECT ALL RELEVANT SIGNALS TO IT
		sc.connect("SpotAproached", Arrival)
		sc.connect("SpotSearched", SearchLocation)
		sc.connect("SpotAnalazyed", AnalyzeLocation)
		
		#var AddingStation = false
		#DECIDE ON TYPE
		var type
		
		if (g == MapSize - 1):
			type = FinalSpotType
			#AddingStation = true
		else :if (SpecialSpots.has(g)):
			type = SpecialMapSpotTypes[SpecialSpots.find(g)] as MapSpotType
		else : if (StationSpots.has(g)):
			type = MinorStationSpotType as MapSpotType
			#AddingStation = true
		else:
			type = MapSpotTypes.pick_random() as MapSpotType
		#SET THE TYPE
		sc.SetSpotData(type)
		
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
		#if (AddingStation):
			#line.add_point(pos)
		#REPEAT PROCESS FOR ASTEROID FIELD
		var asteroidscene = SpotScene.instantiate() as MapSpot
		$CanvasLayer/UIMaster/SubViewportContainer/SubViewport/MapSpots/SpotSpot.add_child(asteroidscene)
		asteroidscene.connect("SpotAproached", Arrival)
		asteroidscene.connect("SpotSearched", SearchLocation)
		asteroidscene.connect("SpotAnalazyed", AnalyzeLocation)
		asteroidscene.SetSpotData(CommetMapSpots.pick_random())

		var ateroidpos = GetNextRandomPos(Prevpos, Distanceval)
		while (HasClose(ateroidpos)):
			ateroidpos = GetNextRandomPos(Prevpos, Distanceval)
		asteroidscene.position = ateroidpos
		SpotList.append(asteroidscene)
		#MAKE SURE TO SAVE POSITION OF PLACED MAP SPOT FOR NEXT ITERRATION
		Prevpos = pos
		
func GetNextRandomPos(PrevPos : Vector2, Distance : float) -> Vector2:
	return Vector2(randf_range(PrevPos.x, PrevPos.x + (800 * Distance)), randf_range(-800, +800))
#TODO IMPROVE
func HasClose(pos : Vector2) -> bool:
	var b= false
	for z in SpotList.size():
		if (pos.distance_to(SpotList[z].position) < 50):
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
func AnalyzeLocation(Spot : MapSpot):
	var analyzer = AnalyzerScene.instantiate() as PlanetAnalyzer
	analyzer.SetVisuals(Spot)
	Ingame_UIManager.GetInstance().add_child(analyzer)

func SearchLocation(stage : MapSpot):
	if (GetPlayerShip().Travelling):
		PopUpManager.GetInstance().DoPopUp("Stop the ship to land.")
		return
	#stage.ToggleLandButton(false)
	if (stage.SpotType is Ship_MapSpotType):
		MAP_ShipSearched.emit(stage.SpotType.Ship)
	else:
		MAP_StageSearched.emit(stage)
	stage.OnSpotVisited()

#Save/Load///////////////////////////////////////////
func GetSaveData() ->SaveData:
	var dat = SaveData.new().duplicate()
	dat.DataName = "MapSpots"
	var Datas : Array[Resource] = []
	for g in SpotList.size():
		if (SpotList[g] == null):
			continue
		Datas.append(SpotList[g].GetSaveData())
	dat.Datas = Datas
	return dat
func LoadSaveData(Data : Array[Resource]) -> void:
	for g in Data.size():
		var dat = Data[g] as MapSpotSaveData
		var sc = SpotScene.instantiate() as MapSpot
		$CanvasLayer/UIMaster/SubViewportContainer/SubViewport/MapSpots/SpotSpot.add_child(sc)
		#sc.connect("MapPressed", Arrival)
		sc.connect("SpotAproached", Arrival)
		sc.connect("SpotSearched", SearchLocation)
		sc.connect("SpotAnalazyed", AnalyzeLocation)
		var type = dat.SpotType
		sc.SetSpotData(type)
		sc.Pos = dat.SpotLoc
		SpotList.insert(g, sc)
		if (dat.Seen):
			sc.OnSpotSeen(false)
		
		sc.Visited = dat.Visited
		
		if (dat.Analyzed):
			sc.OnSpotAnalyzed()

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
	camera_2d.zoom = clamp(prevzoom * Vector2(zoomval, zoomval), Vector2(0.25,0.25), Vector2(2,2))
	for g in get_tree().get_nodes_in_group("MapShipVizualiser"):
		g.visible = camera_2d.zoom < Vector2(1, 1)
	for g in get_tree().get_nodes_in_group("MapLines"):
		g.material.set_shader_parameter("line_width", lerp(0.01, 0.001, camera_2d.zoom.x / 2))
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
		camera_2d.zoom = clamp(start_zoom / zoom_factor, Vector2(0.25,0.25), Vector2(2,2))
		for g in get_tree().get_nodes_in_group("MapLines"):
			g.material.set_shader_parameter("line_width", lerp(0.01, 0.001, camera_2d.zoom.x / 2))
	else:
		UpdateCameraPos(event.relative)	
#//////////////////////////////////////////////////////////
#ARROW FOR LOCATING PLAYER SHIP
func _process(_delta: float) -> void:
	$CanvasLayer/UIMaster/SubViewportContainer/SubViewport/Camera2D/ArrowSprite.look_at(GetPlayerShip().global_position)
func PlayerEnteredScreen() -> void:
	set_process(false)
	$CanvasLayer/UIMaster/SubViewportContainer/SubViewport/Camera2D/ArrowSprite.visible = false
func PlayerExitedScreen() -> void:
	set_process(true)
	$CanvasLayer/UIMaster/SubViewportContainer/SubViewport/Camera2D/ArrowSprite.visible = true
#//////////////////////////////////////////////////////////

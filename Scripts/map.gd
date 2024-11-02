extends Node2D
class_name Map

@export var SpotScene: PackedScene
@export var MapSpotTypes : Array[MapSpotType]
@export var SpecialMapSpotTypes : Array[MapSpotType]
@export var CommetMapSpots : Array[MapSpotType]
@export var FinalSpotType : MapSpotType
@export var MapSize : int = 20
@export var AnalyzerScene : PackedScene
@export var MapGenerationDistanceCurve : Curve
@onready var player_ship: PlayerShip = $MapSpots/PlayerShip
@onready var thrust_slider: ThrustSlider = $CanvasLayer/ThrustSlider
@onready var camera_2d: Camera2D = $Camera2D


#var Travelling = false

signal AsteroidBeltArrival(Size : int)
signal StageSearched(Spt : MapSpotType)
signal ShipSearched(Ship : BaseShip)

var SpotList : Array[MapSpot]
var currentstage = 0
var GalaxyMat :ShaderMaterial

func ToggleVis(t : bool ):
	visible = t
	$CanvasLayer.visible = t

func _ready() -> void:
	if (SpotList.size() == 0):
		GenerateMap()
	var shipdata = ShipData.GetInstance()
	player_ship.UpdateFuelRange(shipdata.GetStat("FUEL").GetCurrentValue(), shipdata.GetStat("FUEL_EFFICIENCY").GetStat())
	player_ship.UpdateVizRange(shipdata.GetStat("VIZ_RANGE").GetStat())
	player_ship.UpdateAnalyzerRange(shipdata.GetStat("ANALYZE_RANGE").GetStat())
	GalaxyMat = $Control/ColorRect.material
	
	camera_2d.make_current()

func GetPlayerPos() -> Vector2:
	return $MapSpots/PlayerShip.position

func SetPlayerPos(pos : Vector2) -> void:
	$MapSpots/PlayerShip.position = pos

func GetPlayerShip() -> PlayerShip:
	return $MapSpots/PlayerShip
#var touch_points: Dictionary = {}
#var start_zoom: Vector2
#var start_dist: float
#func _handle_touch(event: InputEventScreenTouch):
#	if event.pressed:
#		touch_points[event.index] = event.position
#	else:
#		touch_points.erase(event.index)

#	if touch_points.size() == 2:
#		var touch_point_positions = touch_points.values()
#		start_dist = touch_point_positions[0].distance_to(touch_point_positions[1])
#		start_zoom = camera_2d.zoom
#		start_dist = 0
#func _handle_drag(event: InputEventScreenDrag):
#	touch_points[event.index] = event.position

#	if touch_points.size() == 2 :
#		var touch_point_positions = touch_points.values()
#		var current_dist = touch_point_positions[0].distance_to(touch_point_positions[1])

#		var zoom_factor = start_dist / (current_dist / 100)
##		camera_2d.zoom = clamp(start_zoom / zoom_factor, Vector2(0.5,0.5), Vector2(2,2))

func UpdateCameraPos(relativeMovement : Vector2):
	var maxposX = $MapSpots/SpotSpot.get_child($MapSpots/SpotSpot.get_child_count()-1).position.x
	var vpsizehalf = (get_viewport_rect().size.y / 2)
	var maxposY = Vector2(vpsizehalf - 900 * camera_2d.zoom.x, vpsizehalf + 900 * camera_2d.zoom.x)
	var rel = relativeMovement
	var newpos = Vector2(clamp(camera_2d.position.x - rel.x, 0, maxposX), clamp(camera_2d.position.y - rel.y, maxposY.x, maxposY.y))
	if (newpos.x != camera_2d.position.x):
		camera_2d.position.x = newpos.x
		var val = GalaxyMat.get_shader_parameter("thing")
		GalaxyMat.set_shader_parameter("thing", val - (rel.x / 500) * camera_2d.zoom.x)
	if (newpos.y != camera_2d.position.y):
		camera_2d.position.y = newpos.y
		var val2 = GalaxyMat.get_shader_parameter("thing2")
		GalaxyMat.set_shader_parameter("thing2", val2 - (rel.y / 500) * camera_2d.zoom.x)
		
func _input(event: InputEvent) -> void:
	pass
		
func _process(_delta: float) -> void:
	#if (Input.is_action_pressed("MapLeft")):
	#	if ($MapSpots.position.x < 250):
	#		var spots = get_node("MapSpots") as Control
	#		spots.position.x += 15
	#		var val = GalaxyMat.get_shader_parameter("thing")
	#		GalaxyMat.set_shader_parameter("thing", val - 0.02)
	#if (Input.is_action_pressed("MapRight")):
	#	if (SpotList[SpotList.size() - 1].global_position.x + 150 > $MapSpots.size.x):
	#		var spots = get_node("MapSpots") as Control
	#		spots.position.x -= 15
	#		var val = GalaxyMat.get_shader_parameter("thing")
	#		GalaxyMat.set_shader_parameter("thing", val + 0.02)
	#if (Input.is_action_pressed("MapDown")):
	#	if (-$MapSpots.position.y  < $MapSpots.size.y):
	#		var spots = get_node("MapSpots") as Control
	#		spots.position.y -= 15
	#		var val = GalaxyMat.get_shader_parameter("thing2")
	#		GalaxyMat.set_shader_parameter("thing2", val + 0.02)
	#if (Input.is_action_pressed("MapUp")):
	#	if ($MapSpots.position.y  < $MapSpots.size.y):
	#		var spots = get_node("MapSpots") as Control
	#		spots.position.y += 15
	#		var val = GalaxyMat.get_shader_parameter("thing2")
	#		GalaxyMat.set_shader_parameter("thing2", val - 0.02)
	$Camera2D/ArrowSprite.look_at(player_ship.global_position)

func GenerateMap() -> void:
	var SpecialSpots : Array[int] = []
	for z in SpecialMapSpotTypes.size():
		SpecialSpots.append(randi_range(5, MapSize - 1))
	var Prevpos : Vector2 = Vector2(250,250)
	for g in MapSize :
		var sc = SpotScene.instantiate() as MapSpot
		$MapSpots/SpotSpot.add_child(sc)
		sc.connect("SpotAproached", Arrival)
		sc.connect("SpotSearched", SearchLocation)
		sc.connect("SpotAnalazyed", AnalyzeLocation)
		var type
		if (SpecialSpots.has(g)):
			type = SpecialMapSpotTypes[SpecialSpots.find(g)] as MapSpotType
		else:
			type = MapSpotTypes.pick_random() as MapSpotType
		if (g == MapSize - 1):
			type = FinalSpotType
		sc.SetSpotData(type)
		
		var Distanceval = MapGenerationDistanceCurve.sample(g / (MapSize as float))
		
		var pos = GetNextRandomPos(Prevpos, Distanceval)
		while (HasClose(pos)):
			pos = GetNextRandomPos(Prevpos, Distanceval)
		sc.position = pos
		SpotList.append(sc)
		
		var asteroidscene = SpotScene.instantiate() as MapSpot
		$MapSpots/SpotSpot.add_child(asteroidscene)
		asteroidscene.connect("SpotAproached", Arrival)
		asteroidscene.connect("SpotSearched", SearchLocation)
		asteroidscene.connect("SpotAnalazyed", AnalyzeLocation)
		asteroidscene.SetSpotData(CommetMapSpots.pick_random())

		var ateroidpos = GetNextRandomPos(Prevpos, Distanceval)
		while (HasClose(ateroidpos)):
			ateroidpos = GetNextRandomPos(Prevpos, Distanceval)
		asteroidscene.position = ateroidpos
		SpotList.append(asteroidscene)
		
		Prevpos = pos
		
func GetNextRandomPos(PrevPos : Vector2, Distance : float) -> Vector2:
	return Vector2(randf_range(PrevPos.x, PrevPos.x + (800 * Distance)), randf_range(-800, +800))
func HasClose(pos : Vector2) -> bool:
	var b= false
	for z in SpotList.size():
		if (pos.distance_to(SpotList[z].position) < 50):
			b = true
	return b	
	
#called by World after stage is finished and we have reached the new planet
func Arrival(Spot : MapSpot)	-> void:
	if Spot.SpotType.FullName == "Black Whole":
		var randspot = SpotList.pick_random() as MapSpot
		while abs(SpotList.find(randspot) - SpotList.find(Spot)) > 25 or randspot.SpotType.FullName == "Black Whole":
			randspot = SpotList.pick_random() as MapSpot
		player_ship.global_position = randspot.global_position
		PopUpManager.GetInstance().DoPopUp("You've entered a black whole and have been teleported away")
		player_ship.HaltShip()
		
	if Spot.SpotType.GetEnumString() == "ASTEROID_BELT":
		Spot.queue_free()
		var val = Spot.SpotType.GetCustomData("IsLarge") as bool
		if (val):
			AsteroidBeltArrival.emit(120)
		else:
			AsteroidBeltArrival.emit(60)
		player_ship.HaltShip()
		
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
	
# Called when clicked on a planet
func AnalyzeLocation(Spot : MapSpot):
	var analyzer = AnalyzerScene.instantiate() as PlanetAnalyzer
	analyzer.SetVisuals(Spot)
	Ingame_UIManager.GetInstance().add_child(analyzer)
	
func SearchLocation(stage : MapSpot):
	if (player_ship.Travelling):
		PopUpManager.GetInstance().DoPopUp("Stop the ship to land.")
		return
	#stage.ToggleLandButton(false)
	if (stage.SpotType is Ship_MapSpotType):
		ShipSearched.emit(stage.SpotType.Ship)
	else:
		StageSearched.emit(stage)
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
		$MapSpots/SpotSpot.add_child(sc)
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
		if (dat.Visited):
			sc.OnSpotVisited()
		if (dat.Analyzed):
			sc.OnSpotAnalyzed()
#//////////////////////////////////////////////////////////
func PlayerEnteredScreen() -> void:
	$Camera2D/ArrowSprite.visible = false

func PlayerExitedScreen() -> void:
	$Camera2D/ArrowSprite.visible = true
	
var MouseInUI = false


func _on_accelleration_slider_mouse_entered() -> void:
	MouseInUI = true
func _on_accelleration_slider_mouse_exited() -> void:
	MouseInUI = false
func _on_steer_slider_mouse_entered() -> void:
	MouseInUI = true
func _on_steer_slider_mouse_exited() -> void:
	MouseInUI = false


var shakestr = 0.0

func applyshake():
	shakestr = 1
	
func _physics_process(delta: float) -> void:
	if shakestr > 0.0:
		shakestr = lerpf(shakestr, 0, 5.0 * delta)
		var of = RandomOffset()
		camera_2d.offset = of

func RandomOffset()-> Vector2:
	return Vector2(randf_range(-shakestr, shakestr), randf_range(-shakestr, shakestr))
	
func ShipStartedMoving():
	applyshake()
	
func ShipStoppedMoving():
	pass
func ShipForcedStop():
	thrust_slider.ZeroAcceleration()

func _on_screen_gui_input(event: InputEvent) -> void:
	if (event.is_action_pressed("ZoomIn")):
		camera_2d.zoom = clamp(camera_2d.zoom * Vector2(1.1, 1.1), Vector2(0.5,0.5), Vector2(2,2))
	if (event.is_action_pressed("ZoomOut")):
		camera_2d.zoom = clamp(camera_2d.zoom / Vector2(1.1, 1.1), Vector2(0.5,0.5), Vector2(2,2))
	if (player_ship.ChangingCourse or MouseInUI):
		return
#	if (event is InputEventScreenTouch):
#		_handle_touch(event)
	if (event is InputEventScreenDrag):
#		_handle_drag(event)
		UpdateCameraPos(event.relative)
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		UpdateCameraPos(event.relative)

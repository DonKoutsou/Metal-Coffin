extends Control
class_name Map

@export var SpotScene: PackedScene
@export var MapSpotTypes : Array[MapSpotType]
@export var SpecialMapSpotTypes : Array[MapSpotType]
@export var FinalSpotType : MapSpotType
@export var MapSize = 20
@export var AnalyzerScene : PackedScene

@onready var player_ship: Sprite2D = $MapSpots/PlayerShip


signal StageSellected(st : MapSpotType, stNum : int, fuelcons : float, o2Cons : float)
signal StageSearched(Drops : Array[Item])
signal ShipSearched(Ship : BaseShip)
var PlayingStage = false

var SpotList : Array[MapSpot]
var currentstage = 0
var GalaxyMat :ShaderMaterial

func GetPlayerPos() -> Vector2:
	return $MapSpots/PlayerShip.position
func SetPlayerPos(pos : Vector2) -> void:
	$MapSpots/PlayerShip.position = pos
func _ready() -> void:
	if (SpotList.size() == 0):
		GenerateMap()
	ToggleClose()
	var shipdata = ShipData.GetInstance()
	UpdateFuelRange(shipdata.GetStat("FUEL").GetCurrentValue(), shipdata.GetStat("FUEL_EFFICIENCY").GetStat())
	UpdateVizRange(shipdata.GetStat("VIZ_RANGE").GetStat())
	UpdateAnalyzerRange(shipdata.GetStat("ANALYZE_RANGE").GetStat())
	GalaxyMat = $ColorRect.material
func UpdateShipIcon(Tex : Texture) -> void:
	$MapSpots/PlayerShip.texture = Tex
func GetSaveData() ->SaveData:
	var dat = SaveData.new().duplicate()
	dat.DataName = "MapSpots"
	var Datas : Array[Resource] = []
	for g in SpotList.size():
		Datas.append(SpotList[g].GetSaveData())
	dat.Datas = Datas
	return dat
func LoadSaveData(Data : Array[Resource]) -> void:
	for g in Data.size():
		var dat = Data[g] as MapSpotSaveData
		var sc = SpotScene.instantiate() as MapSpot
		$MapSpots/SpotSpot.add_child(sc)
		sc.connect("MapPressed", StartStage)
		sc.connect("SpotSearched", SpotSearched)
		sc.connect("SpotAnalazyed", AnalyzeStage)
		var type = dat.SpotType
		sc.SetSpotData(type)
		sc.Pos = dat.SpotLoc
		SpotList.insert(g, sc)
		if (dat.Seen):
			sc.OnSpotSeen()
		if (dat.Visited):
			sc.OnSpotVisited()
		
func _process(_delta: float) -> void:
	if (PlayingStage):
		return
	if (Input.is_action_pressed("MapLeft")):
		if ($MapSpots.position.x >= 250):
			return
		var spots = get_node("MapSpots") as Control
		spots.position.x += 15
		var val = GalaxyMat.get_shader_parameter("thing")
		GalaxyMat.set_shader_parameter("thing", val - 0.02)
	if (Input.is_action_pressed("MapRight")):
		if (SpotList[SpotList.size() - 1].global_position.x + 150 <= $MapSpots.size.x):
			return
		var spots = get_node("MapSpots") as Control
		spots.position.x -= 15
		var val = GalaxyMat.get_shader_parameter("thing")
		GalaxyMat.set_shader_parameter("thing", val + 0.02)
		
func GenerateMap() -> void:
	var VP= $MapSpots.size
	VP.x /= 10
	var SpecialSpots : Array[int] = []
	for z in SpecialMapSpotTypes.size():
		SpecialSpots.append(randi_range(5, MapSize - 1))
	for g in MapSize :
		var sc = SpotScene.instantiate() as MapSpot
		$MapSpots/SpotSpot.add_child(sc)
		sc.connect("MapPressed", StartStage)
		sc.connect("SpotSearched", SpotSearched)
		sc.connect("SpotAnalazyed", AnalyzeStage)
		var type
		if (SpecialSpots.has(g)):
			type = SpecialMapSpotTypes[SpecialSpots.find(g)] as MapSpotType
		else:
			type = MapSpotTypes.pick_random() as MapSpotType
		if (g == MapSize - 1):
			type = FinalSpotType
		sc.SetSpotData(type)

		var pos = Vector2(randf_range(VP.x *g, VP.x * (g + 2)) + 50, randf_range(20, VP.y - 80))
		while (HasClose(pos)):
			pos =Vector2(randf_range(VP.x * g,VP.x * (g + 2)) + 50, randf_range(20, VP.y -80))
		sc.position = pos
		SpotList.append(sc)
	
func StageCleared(st : int)	-> void:
	PlayingStage = false
	if (currentstage >= 0):
		var spotprev = SpotList[currentstage] as MapSpot
		spotprev.ToggleLandButton(false)
	var spot = SpotList[st] as MapSpot
	while spot.SpotType.FullName == "Black Whole":
		spot = SpotList.pick_random()
		while abs(SpotList.find(spot) - currentstage) > 25 :
			spot = SpotList.pick_random()
	currentstage = st
	if (currentstage >= SpotList.size()):
		return
	if (!spot.Visited):
		spot.ToggleLandButton(true)
	player_ship.global_position = spot.global_position
	ToggleClose()
	
func StageFailed() -> void:
	PlayingStage = false
func StartStage(stage :MapSpot) -> void:
	var stagenum = SpotList.find(stage)
	var fuel = player_ship.global_position.distance_to(stage.global_position) / 10 / ShipData.GetInstance().GetStat("FUEL_EFFICIENCY").GetStat()
	var o2 = player_ship.global_position.distance_to(stage.global_position) / 40
	StageSellected.emit(stage, stagenum, fuel, o2)
	PlayingStage = true
	pass
func AnalyzeStage(Type : MapSpotType):
	var analyzer = AnalyzerScene.instantiate() as PlanetAnalyzer
	analyzer.SetVisuals(Type)
	add_child(analyzer)
func SpotSearched(stage : MapSpot, sups : Array[Item]):
	stage.ToggleLandButton(false)
	if (stage.SpotType is Ship_MapSpotType):
		ShipSearched.emit(stage.SpotType.Ship)
	else:	
		StageSearched.emit(sups)
	stage.OnSpotVisited()
	
func HasClose(pos : Vector2) -> bool:
	var b= false
	for z in SpotList.size():
		if (pos.distance_to(SpotList[z].position) < 80):
			b = true
	return b
func UpdateFuelRange(fuel : float, fuel_ef : float):
	var distall = fuel * 10 * fuel_ef
	$MapSpots/PlayerShip/Fuel_Range.size = Vector2(distall, distall) * 2
	$MapSpots/PlayerShip/Fuel_Range.position = Vector2(-(distall), -(distall))
	ToggleClose()
func UpdateVizRange(rang : float):
	$MapSpots/PlayerShip/Radar_Range.size = Vector2(rang, rang) * 2
	$MapSpots/PlayerShip/Radar_Range.position = Vector2(-(rang), -(rang))
	ToggleClose()
func UpdateAnalyzerRange(rang : float):
	$MapSpots/PlayerShip/Analyzer_Range.size = Vector2(rang, rang) * 2
	$MapSpots/PlayerShip/Analyzer_Range.position = Vector2(-(rang), -(rang))
	ToggleClose()
func ToggleClose() -> void:
	var pldata = ShipData.GetInstance()
	var distall = pldata.GetStat("FUEL").GetCurrentValue() * 10 * pldata.GetStat("FUEL_EFFICIENCY").GetStat()
	for z in SpotList.size():
		var dist = player_ship.global_position.distance_to(SpotList[z].global_position)
		SpotList[z].ToggleVisitButton(dist < distall and dist > 4)
		if (dist <= pldata.GetStat("VIZ_RANGE").GetStat()):
			SpotList[z].OnSpotSeen()
		SpotList[z].ToggleAnalyzeButton(dist <= pldata.GetStat("ANALYZE_RANGE").GetStat())
		

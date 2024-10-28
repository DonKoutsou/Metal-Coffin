extends Control
class_name Map

@export var SpotScene: PackedScene
@export var MapSpotTypes : Array[MapSpotType]
@export var SpecialMapSpotTypes : Array[MapSpotType]
@export var FinalSpotType : MapSpotType
@export var MapSize = 20
@export var AnalyzerScene : PackedScene

@onready var player_ship: Node2D = $MapSpots/PlayerShip

var Travelling = false

signal StageSellected(st : MapSpotType, stNum : int, fuelcons : float, o2Cons : float)
signal StageSearched(Spt : MapSpotType)
signal ShipSearched(Ship : BaseShip)

var SpotList : Array[MapSpot]
var currentstage = 0
var GalaxyMat :ShaderMaterial

func _ready() -> void:
	if (SpotList.size() == 0):
		GenerateMap()
	var shipdata = ShipData.GetInstance()
	UpdateFuelRange(shipdata.GetStat("FUEL").GetCurrentValue(), shipdata.GetStat("FUEL_EFFICIENCY").GetStat())
	UpdateVizRange(shipdata.GetStat("VIZ_RANGE").GetStat())
	UpdateAnalyzerRange(shipdata.GetStat("ANALYZE_RANGE").GetStat())
	GalaxyMat = $ColorRect.material

func GetPlayerPos() -> Vector2:
	return $MapSpots/PlayerShip.position
signal OnLookAtEnded()
func LookAtEnded():
	OnLookAtEnded.emit()
func PlayerLookAt(LookPos : Vector2) -> void:
	var tw = create_tween()
	tw.tween_property(player_ship, "rotation", player_ship.position.angle_to_point(LookPos), 1)
	tw.connect("finished", LookAtEnded)
	
func SetPlayerPos(pos : Vector2) -> void:
	$MapSpots/PlayerShip.position = pos
	
func UpdateShipIcon(Tex : Texture) -> void:
	$MapSpots/PlayerShip/PlayerShipSpr.texture = Tex
	
func _input(event: InputEvent) -> void:
	if (event is InputEventScreenDrag):
		var maxposX = $MapSpots/SpotSpot.get_child($MapSpots/SpotSpot.get_child_count()-1).position.x - ($MapSpots.size.x - 400)
		var rel = event.relative
		var spots = get_node("MapSpots") as Control
		var newpos = Vector2(clamp(spots.position.x + (rel.x/4), -maxposX, $MapSpots.size.x - 800), clamp(spots.position.y + (rel.y/4), -800, 800))
		spots.position = newpos
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		var maxposX = $MapSpots/SpotSpot.get_child($MapSpots/SpotSpot.get_child_count()-1).position.x - ($MapSpots.size.x - 400)
		var rel = event.relative
		var spots = get_node("MapSpots") as Control
		var newpos = Vector2(clamp(spots.position.x + rel.x, -maxposX, $MapSpots.size.x - 800), clamp(spots.position.y + rel.y, -800, 800))
		spots.position = newpos
func _process(_delta: float) -> void:
	if (Input.is_action_pressed("MapLeft")):
		if ($MapSpots.position.x < 250):
			var spots = get_node("MapSpots") as Control
			spots.position.x += 15
			var val = GalaxyMat.get_shader_parameter("thing")
			GalaxyMat.set_shader_parameter("thing", val - 0.02)
	if (Input.is_action_pressed("MapRight")):
		if (SpotList[SpotList.size() - 1].global_position.x + 150 > $MapSpots.size.x):
			var spots = get_node("MapSpots") as Control
			spots.position.x -= 15
			var val = GalaxyMat.get_shader_parameter("thing")
			GalaxyMat.set_shader_parameter("thing", val + 0.02)
	if (Input.is_action_pressed("MapDown")):
		if (-$MapSpots.position.y  < $MapSpots.size.y):
			var spots = get_node("MapSpots") as Control
			spots.position.y -= 15
			var val = GalaxyMat.get_shader_parameter("thing2")
			GalaxyMat.set_shader_parameter("thing2", val + 0.02)
	if (Input.is_action_pressed("MapUp")):
		if ($MapSpots.position.y  < $MapSpots.size.y):
			var spots = get_node("MapSpots") as Control
			spots.position.y += 15
			var val = GalaxyMat.get_shader_parameter("thing2")
			GalaxyMat.set_shader_parameter("thing2", val - 0.02)
	$ArrowSprite.look_at(player_ship.global_position)

func GenerateMap() -> void:
	var VP= $MapSpots.size
	VP.x /= 10
	var SpecialSpots : Array[int] = []
	for z in SpecialMapSpotTypes.size():
		SpecialSpots.append(randi_range(5, MapSize - 1))
	for g in MapSize :
		var sc = SpotScene.instantiate() as MapSpot
		$MapSpots/SpotSpot.add_child(sc)
		sc.connect("MapPressed", DepartForLocation)
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

		var pos = Vector2(randf_range(VP.x *g, VP.x * (g + 2)) + 50, randf_range(-500, VP.y +500))
		while (HasClose(pos)):
			pos =Vector2(randf_range(VP.x * g,VP.x * (g + 2)) + 50, randf_range(-500, VP.y  +500))
		sc.position = pos
		SpotList.append(sc)
	
#called by World after stage is finished and we have reached the new planet
func Arrival(st : int)	-> void:
	# enable inputs
	Travelling = false
	set_process(true)
	set_process_input(true)
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
	spot.ToggleVisitButton(false)
	
func StageFailed() -> void:
	# enable inputs
	set_process(true)
	set_process_input(true)
	Travelling = false
	
func DepartForLocation(stage :MapSpot) -> void:
	if (Travelling):
		return
	var spotprev = SpotList[currentstage] as MapSpot
	spotprev.ToggleVisitButton(true)
	spotprev.ToggleLandButton(false)
	Travelling = true
	var stagenum = SpotList.find(stage)
	var fuel = player_ship.global_position.distance_to(stage.global_position) / 10 / ShipData.GetInstance().GetStat("FUEL_EFFICIENCY").GetStat()
	var o2 = player_ship.global_position.distance_to(stage.global_position) / 40
	StageSellected.emit(stage, stagenum, fuel, o2)
	# enable inputs
	#set_process(false)
	
func AnalyzeLocation(Type : MapSpotType):
	var analyzer = AnalyzerScene.instantiate() as PlanetAnalyzer
	analyzer.SetVisuals(Type)
	add_child(analyzer)
	
func SearchLocation(stage : MapSpot):
	if (Travelling):
		return
	#stage.ToggleLandButton(false)
	if (stage.SpotType is Ship_MapSpotType):
		ShipSearched.emit(stage.SpotType.Ship)
	else:
		StageSearched.emit(stage)
	stage.OnSpotVisited()
	
func HasClose(pos : Vector2) -> bool:
	var b= false
	for z in SpotList.size():
		if (pos.distance_to(SpotList[z].position) < 80):
			b = true
	return b
	
func UpdateFuelRange(fuel : float, fuel_ef : float):
	var distall = fuel * 10 * fuel_ef
	($MapSpots/PlayerShip/Fuel/CollisionShape2D.shape as CircleShape2D).radius = distall
	$MapSpots/PlayerShip/Fuel/Fuel_Range.size = Vector2(distall, distall) * 2
	$MapSpots/PlayerShip/Fuel/Fuel_Range/Label.visible = distall > 100
	$MapSpots/PlayerShip/Fuel/Fuel_Range.position = Vector2(-(distall), -(distall))

func UpdateVizRange(rang : float):
	($MapSpots/PlayerShip/Radar/CollisionShape2D.shape as CircleShape2D).radius = rang
	$MapSpots/PlayerShip/Radar/Radar_Range.size = Vector2(rang, rang) * 2
	$MapSpots/PlayerShip/Radar/Radar_Range/Label2.visible = rang > 100
	$MapSpots/PlayerShip/Radar/Radar_Range.position = Vector2(-(rang), -(rang))

func UpdateAnalyzerRange(rang : float):
	($MapSpots/PlayerShip/Analyzer/CollisionShape2D.shape as CircleShape2D).radius = rang
	$MapSpots/PlayerShip/Analyzer/Analyzer_Range.size = Vector2(rang, rang) * 2
	$MapSpots/PlayerShip/Analyzer/Analyzer_Range/Label2.visible = rang > 100
	$MapSpots/PlayerShip/Analyzer/Analyzer_Range.position = Vector2(-(rang), -(rang))

#Save/Load///////////////////////////////////////////
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
		sc.connect("MapPressed", Arrival)
		sc.connect("SpotSearched", SearchLocation)
		sc.connect("SpotAnalazyed", AnalyzeLocation)
		var type = dat.SpotType
		sc.SetSpotData(type)
		sc.Pos = dat.SpotLoc
		SpotList.insert(g, sc)
		if (dat.Seen):
			sc.OnSpotSeen()
		if (dat.Visited):
			sc.OnSpotVisited()
#//////////////////////////////////////////////////////////
func _on_player_viz_notifier_screen_entered() -> void:
	$ArrowSprite.visible = false


func _on_player_viz_notifier_screen_exited() -> void:
	$ArrowSprite.visible = true

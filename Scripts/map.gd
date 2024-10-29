extends Control
class_name Map

@export var SpotScene: PackedScene
@export var MapSpotTypes : Array[MapSpotType]
@export var SpecialMapSpotTypes : Array[MapSpotType]
@export var CommetMapSpot : MapSpotType
@export var FinalSpotType : MapSpotType
@export var MapSize = 20
@export var AnalyzerScene : PackedScene

@onready var player_ship: PlayerShip = $MapSpots/PlayerShip


var Travelling = false

signal AsteroidBeltArrival()
signal StageSearched(Spt : MapSpotType)
signal ShipSearched(Ship : BaseShip)

var SpotList : Array[MapSpot]
var currentstage = 0
var GalaxyMat :ShaderMaterial

func _ready() -> void:
	if (SpotList.size() == 0):
		GenerateMap()
	var shipdata = ShipData.GetInstance()
	player_ship.UpdateFuelRange(shipdata.GetStat("FUEL").GetCurrentValue(), shipdata.GetStat("FUEL_EFFICIENCY").GetStat())
	player_ship.UpdateVizRange(shipdata.GetStat("VIZ_RANGE").GetStat())
	player_ship.UpdateAnalyzerRange(shipdata.GetStat("ANALYZE_RANGE").GetStat())
	GalaxyMat = $ColorRect.material
	set_physics_process(false)

func GetPlayerPos() -> Vector2:
	return $MapSpots/PlayerShip.position
signal OnLookAtEnded()
func LookAtEnded():
	OnLookAtEnded.emit()
func PlayerLookAt(LookPos : Vector2) -> void:
	var tw = create_tween()
	tw.tween_property(player_ship, "rotation", player_ship.position.angle_to_point(LookPos), 1)
	tw.connect("finished", LookAtEnded)
func PlayerRotate(Rotation : float) -> void:
	var tw = create_tween()
	tw.tween_property(player_ship, "rotation", Rotation, 1)
func SetPlayerPos(pos : Vector2) -> void:
	$MapSpots/PlayerShip.position = pos
func UpdateShipIcon(Tex : Texture) -> void:
	$MapSpots/PlayerShip/PlayerShipSpr.texture = Tex
	
func _input(event: InputEvent) -> void:
	if (ChangingCourse or MouseInUI):
		return
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

		var pos = Vector2(randf_range(VP.x *g, VP.x * (g + 2)) + 50, randf_range(-500, VP.y +500))
		while (HasClose(pos)):
			pos =Vector2(randf_range(VP.x * g,VP.x * (g + 2)) + 50, randf_range(-500, VP.y  +500))
		sc.position = pos
		SpotList.append(sc)
		
		var asteroidscene = SpotScene.instantiate() as MapSpot
		$MapSpots/SpotSpot.add_child(asteroidscene)
		asteroidscene.connect("SpotAproached", Arrival)
		asteroidscene.connect("SpotSearched", SearchLocation)
		asteroidscene.connect("SpotAnalazyed", AnalyzeLocation)
		asteroidscene.SetSpotData(CommetMapSpot)

		var ateroidpos = Vector2(randf_range(VP.x *g, VP.x * (g + 2)) + 50, randf_range(-500, VP.y +500))
		while (HasClose(ateroidpos)):
			ateroidpos =Vector2(randf_range(VP.x * g,VP.x * (g + 2)) + 50, randf_range(-500, VP.y  +500))
		asteroidscene.position = ateroidpos
		SpotList.append(asteroidscene)
		
func HasClose(pos : Vector2) -> bool:
	var b= false
	for z in SpotList.size():
		if (pos.distance_to(SpotList[z].position) < 80):
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
		HaltShip()
	if Spot.SpotType.GetEnumString() == "ASTEROID_BELT":
		Spot.queue_free()
		AsteroidBeltArrival.emit()
		HaltShip()
func StageFailed() -> void:
	# enable inputs
	set_process(true)
	set_process_input(true)
	Travelling = false
	
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
	
func AnalyzeLocation(Spot : MapSpot):
	var analyzer = AnalyzerScene.instantiate() as PlanetAnalyzer
	analyzer.SetVisuals(Spot)
	get_parent().add_child(analyzer)
	
func SearchLocation(stage : MapSpot):
	if (Travelling):
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
	$ArrowSprite.visible = false


func PlayerExitedScreen() -> void:
	$ArrowSprite.visible = true

var ChangingCourse = false
var MouseInUI = false
func _on_steer_slider_value_changed(value: float) -> void:
	#ChangingCourse = true
	#var slidersize = $SteerSlider.size.x
	#$SteerSlider/Label.text = var_to_str(value) + "°"
	#$SteerSlider/Label.position.x = (slidersize / 360) * value + (slidersize/2) - ($SteerSlider/Label.size.x / 2)
	PlayerRotate(deg_to_rad(value))
var speed = 0.0
func _physics_process(_delta: float) -> void:
	var fuel = player_ship.global_position.distance_to($MapSpots/PlayerShip/Node2D.global_position) / 10 / ShipData.GetInstance().GetStat("FUEL_EFFICIENCY").GetStat()
	if (ShipData.GetInstance().GetStat("FUEL").GetCurrentValue() < fuel):
		$PanelContainer/HBoxContainer/AccellerationSlider.value = 0
		PopUpManager.GetInstance().DoPopUp("You have run out of fuel.")
		set_physics_process(false)
		return
	player_ship.global_position = $MapSpots/PlayerShip/Node2D.global_position
	var shdat = ShipData.GetInstance()
	shdat.AddToStatCurrentValue("FUEL", -fuel)
	player_ship.UpdateFuelRange(shdat.GetStat("FUEL").GetCurrentValue(), shdat.GetStat("FUEL_EFFICIENCY").GetStat())
func HaltShip():
	speed = 0
	Travelling = false
	set_physics_process(false)
	ChangingCourse = false
	$MapSpots/PlayerShip/Node2D.position.x = speed / 100
	var slidersize = $PanelContainer/HBoxContainer/AccellerationSlider.size.y
	$PanelContainer/HBoxContainer/AccellerationSlider.set_value_no_signal(0)
	$PanelContainer/HBoxContainer/AccellerationSlider/Label.position.y = -(slidersize / 50) * speed + (slidersize) - ($PanelContainer/HBoxContainer/AccellerationSlider/Label.size.y / 2)
	$PanelContainer/HBoxContainer/AccellerationSlider/Label.text = var_to_str(roundi(speed))
func _on_accelleration_slider_value_changed(value: float) -> void:
	ChangingCourse = true
	speed = value
	if (speed == 0):
		Travelling = false
		set_physics_process(false)
	else:
		Travelling = true
		set_physics_process(true)
	$MapSpots/PlayerShip/Node2D.position.x = value / 100
	var slidersize = $PanelContainer/HBoxContainer/AccellerationSlider.size.y
	$PanelContainer/HBoxContainer/AccellerationSlider/Label.position.y = -(slidersize / 50) * value + (slidersize) - ($PanelContainer/HBoxContainer/AccellerationSlider/Label.size.y / 2)
	$PanelContainer/HBoxContainer/AccellerationSlider/Label.text = var_to_str(roundi(value))
	
func _on_accelleration_slider_mouse_entered() -> void:
	MouseInUI = true
func _on_accelleration_slider_mouse_exited() -> void:
	MouseInUI = false
func _on_steer_slider_mouse_entered() -> void:
	MouseInUI = true
func _on_steer_slider_mouse_exited() -> void:
	MouseInUI = false
func _on_accelleration_slider_drag_ended(_value_changed: bool) -> void:
	ChangingCourse = false

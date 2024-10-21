extends Control
class_name Map

@export var SpotScene: PackedScene
@export var MapSpotTypes : Array[MapSpotType]
@export var FinalSpotType : MapSpotType
@export var MapSize = 20
@onready var player_ship: Sprite2D = $MapSpots/PlayerShip
@onready var world: World = $"../.."

signal StageSellected(st : MapSpotType, stNum : int, fuelcons : float)
signal StageSearched(Drops : Array[Item])
var PlayingStage = false

var SpotList : Array[MapSpot]
var currentstage = 0

func _ready() -> void:
	GenerateMap()
	pass # Replace with function body.

func _process(_delta: float) -> void:
	if (PlayingStage):
		return
	if (Input.is_action_pressed("MapLeft")):
		if ($MapSpots.position.x >= 250):
			return
		var spots = get_node("MapSpots") as Control
		spots.position.x += 15
	if (Input.is_action_pressed("MapRight")):
		if (SpotList[SpotList.size() - 1].global_position.x + 150 <= $MapSpots.size.x):
			return
		var spots = get_node("MapSpots") as Control
		spots.position.x -= 15
		
func GenerateMap() -> void:
	var ran = RandomNumberGenerator.new()
	var VP= $MapSpots.size
	VP.x /= 10
	var locse :Dictionary
	for g in MapSize :
		var sc = SpotScene.instantiate() as MapSpot
		$MapSpots/SpotSpot.add_child(sc)
		sc.connect("MapPressed", StartStage)
		sc.connect("SpotSearched", SpotSearched)
		var type = MapSpotTypes.pick_random() as MapSpotType
		if (g == MapSize - 1):
			type = FinalSpotType
		sc.SetSpotData(type)

		var pos = Vector2(ran.randf_range(VP.x *g, VP.x * (g + 2)) + 50, ran.randf_range(20, VP.y - 80))
		while (HasClose(pos)):
			pos =Vector2(ran.randf_range(VP.x * g,VP.x * (g + 2)) + 50, ran.randf_range(20, VP.y -80))
		sc.position = pos
		locse[pos] = sc
		SpotList.insert(g, sc)
		
		#var line = Line2D.new()
		#line.points = [locse.keys()[max(0, g -1)], pos]
		#$MapSpots/Lines.add_child(line)
		#line.antialiased = true
		#line.default_color = Color.AQUA
		
	ToggleClose()
	UpdateFuelRange(world.PlayerDat.FUEL)
	UpdateVizRange(world.PlayerDat.VIZ_RANGE)
	pass
func StageCleared(st : int)	-> void:
	PlayingStage = false
	if (currentstage >= 0):
		var spotprev = SpotList[currentstage] as MapSpot
		spotprev.ToggleLandButton(false)
		
	var spot = SpotList[st] as MapSpot
	while spot.SpotNameSt == "Black Whole":
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
	var fuel = player_ship.global_position.distance_to(stage.global_position) / 10
	StageSellected.emit(stage, stagenum, fuel)
	PlayingStage = true
	pass
func SpotSearched(stage : MapSpot, sups : Array[Item]):
	stage.ToggleLandButton(false)
	StageSearched.emit(sups)
	stage.OnSpotVisited()
	pass
	
func HasClose(pos : Vector2) -> bool:
	var b= false
	for z in SpotList.size():
		if (pos.distance_to(SpotList[z].position) < 80):
			b = true
	return b
func UpdateFuelRange(fuel : float):
	var distall = fuel * 10
	$MapSpots/PlayerShip/Panel.size = Vector2(distall, distall) * 2
	$MapSpots/PlayerShip/Panel.position = Vector2(-(distall), -(distall))
	ToggleClose()
func UpdateVizRange(rang : int):
	$MapSpots/PlayerShip/Panel2.size = Vector2(rang, rang) * 2
	$MapSpots/PlayerShip/Panel2.position = Vector2(-(rang), -(rang))
	ToggleClose()
func ToggleClose() -> void:
	var distall = world.PlayerDat.FUEL * 10
	for z in SpotList.size():
		var dist = player_ship.global_position.distance_to(SpotList[z].global_position)
		SpotList[z].ToggleVisitButton(dist < distall and dist > 0)
		if (dist <= world.PlayerDat.VIZ_RANGE):
			SpotList[z].OnSpotSeen()
		

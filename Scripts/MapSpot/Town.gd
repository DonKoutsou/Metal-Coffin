#@tool
extends Node2D
class_name Town

@export var SpotScene: PackedScene
var LoadingData : bool = false
var Pos : Vector2

var Spot : MapSpot
signal TownSpotAproached(spot : MapSpot)
signal TownSpotLanded(spot : MapSpot)

func _ready() -> void:
	#if (Engine.is_editor_hint()):
		#return
	if (!LoadingData):
		position = Pos
		#rotation = randf_range(0, 360)
		#GenerateCity()
	
func GenerateCity(Type : MapSpotType) -> void:
	var spt = $CitySpot
	var sc = SpotScene.instantiate() as MapSpot
	#var spottype = spt.MapSpotTypes.pick_random() as MapSpotType
	Spot = sc
	sc.connect("SpotAproached", _TownSpotApreached)
	sc.connect("SpotLanded", _TownSpotLanded)
	var pos = spt.position
	sc.position = pos
	spt.replace_by(sc)
	
	sc.SetSpotData(Type)
	
	SetSize()
	
	spt.free()

func SetSize() -> void:
	var SizeThing = ( Spot.Population / 150000.0) as float
	$Sprite2D2.scale = lerp(Vector2(0.3,0.3), Vector2(1.7,1.7),SizeThing)

func IsEnemy() -> bool:
	return Spot.SpotInfo.EnemyCity

func GetSpot() -> MapSpot:
	return Spot
		
func GetSaveData() -> TownSaveData:
	var datas = TownSaveData.new().duplicate()
	datas.TownLoc = position
	#datas.TownRot = rotation
	datas.TownScenePath = scene_file_path
	var spotdata : Array[MapSpotSaveData]
	spotdata.append(Spot.GetSaveData())
	datas.Spots = spotdata
	return datas

func SetMerch(Merch : Array[Merchandise], WorkShopMerch : Array[Merchandise]) -> void:
	GetSpot().Merch = Merch
	GetSpot().WorkShopMerch = WorkShopMerch

func GetCityName() -> String:
	return $CitySpot.SpotName
	
func LoadSaveData(Dat : TownSaveData) -> void:
	position = Dat.TownLoc
	#rotation = Dat.TownRot
	for g in Dat.Spots.size():
		var spotdat = Dat.Spots[g] as MapSpotSaveData
		var sc = SpotScene.instantiate() as MapSpot
		sc.connect("SpotAproached", _TownSpotApreached)
		sc.connect("SpotLanded", _TownSpotLanded)
		
		sc.SetSpotData(spotdat.SpotType)
		
		var CSpot = $CitySpot
		CSpot.replace_by(sc)
		Spot = sc
		sc.position = CSpot.position
		sc.Population = spotdat.Population
		sc.SpotInfo = spotdat.SpotInfo
		sc.PlayerFuelReserves = spotdat.PlayerFuelReserves
		sc.AlarmRaised = spotdat.AlarmRaised
		sc.AlarmProgress = spotdat.AlarmProgress
		sc.Merch = spotdat.Merch
		sc.WorkShopMerch = spotdat.WorkShopMerch
		sc.Event = spotdat.Evnt
		
		sc.SetSize()
		SetSize()
		if (sc.Event != null and spotdat.Evnt.CrewRecruit):
			sc.add_to_group("CrewRecruitTown")
		CSpot.free()

		if (spotdat.Seen):
			sc.OnSpotSeen(false)
			
		if (spotdat.Visited):
			sc.Visited = true
		
func _TownSpotApreached(spot : MapSpot):
	TownSpotAproached.emit(spot)
func _TownSpotLanded(spot : MapSpot):
	TownSpotLanded.emit(spot)

#func _physics_process(delta: float) -> void:
	#if (!Engine.is_editor_hint()):
		#return
	#var Data =  $CitySpot.MapSpotTypes[0].Data as MapSpotCustomData_CompleteInfo
	#for g : MapSpotCompleteInfo in Data.PossibleIds:
		#if (g.PossibleDrops.size() == 0):
			#g.PossibleDrops.append(GetRandomDrop())
			#print("Added drop")
		#
#func GetRandomDrop() -> Item:
	#var Itms = [load("res://Resources/Items/Radioactive.tres"), load("res://Resources/Items/Materials.tres"), load("res://Resources/Items/Supply.tres")]
	#return Itms.pick_random()

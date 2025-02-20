extends Node2D
class_name Town

@export var SpotScene: PackedScene
var LoadingData : bool = false
var Pos : Vector2

var Spot : MapSpot
signal TownSpotAproached(spot : MapSpot)
#signal SpotSearched(spot : MapSpot)
#signal TownSpotAnalazyed(spot : MapSpot)
signal TownSpotLanded(spot : MapSpot)

func _ready() -> void:
	if (!LoadingData):
		position = Pos
		rotation = randf_range(0, 360)
		GenerateCity()
	
func GenerateCity() -> void:
	var spt = $CitySpot as CitySpot
	var sc = SpotScene.instantiate() as MapSpot 
	var spottype = spt.MapSpotTypes.pick_random() as MapSpotType
	Spot = sc
	sc.connect("SpotAproached", _TownSpotApreached)
	sc.connect("SpotLanded", _TownSpotLanded)
	var pos = spt.position
	sc.position = pos
	spt.replace_by(sc)
	sc.SetSpotData(spottype)
	spt.free()
	pass
	
func IsEnemy() -> bool:
	return Spot.SpotInfo.EnemyCity

func GetSpot() -> MapSpot:
	return Spot
	
func SpawnEnemies():
	if (Spot.SpotInfo.HostilePatrolShipScene != null):
		Spot.SpawnEnemyPatrol()
	if (Spot.SpotInfo.HostileShipScene != null):
		Spot.SpawnEnemyGarison()
func GetSaveData() -> TownSaveData:
	var datas = TownSaveData.new().duplicate()
	datas.TownLoc = position
	datas.TownRot = rotation
	datas.TownScenePath = scene_file_path
	var spotdata : Array[MapSpotSaveData]
	spotdata.append(Spot.GetSaveData())
	datas.Spots = spotdata
	return datas

func SetMerch(Merch : Array[Merchandise]) -> void:
	GetSpot().Merch = Merch
#TODO get rid of cities, useless
func GetCityName() -> String:
	return $CitySpot.SpotName
func LoadSaveData(Dat : TownSaveData) -> void:
	position = Dat.TownLoc
	rotation = Dat.TownRot
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
		sc.SpotInfo = spotdat.SpotInfo
		sc.PlayerFuelReserves = spotdat.PlayerFuelReserves
		sc.CityFuelReserves = spotdat.CityFuelReserves
		sc.AlarmRaised = spotdat.AlarmRaised
		sc.AlarmProgress = spotdat.AlarmProgress
		sc.Merch = spotdat.Merch
		CSpot.free()

		if (spotdat.Seen):
			sc.OnSpotSeen(false)
		
		#sc.Visited = spotdat.Visited
		if (spotdat.Visited):
			sc.Visited = true
			
		#if (spotdat.Analyzed):
			#sc.OnSpotAnalyzed(false)
		
func _TownSpotApreached(spot : MapSpot):
	TownSpotAproached.emit(spot)
func _TownSpotLanded(spot : MapSpot):
	TownSpotLanded.emit(spot)

extends Node2D
class_name Town

@export var SpotScene: PackedScene

var LoadingData : bool = false
var Pos : Vector2
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
	var spots = $CitySpots.get_children()
	#var centername : String = ""
	for g in spots:
		var spt = g as CitySpot
		var sc = SpotScene.instantiate() as MapSpot 
		var spottype = spt.MapSpotTypes.pick_random() as MapSpotType

		sc.connect("SpotAproached", _TownSpotApreached)
		#sc.connect("SpotSearched", TownSpotSearched)
		#sc.connect("SpotAnalazyed", _TownSpotAnalyzed)
		sc.connect("SpotLanded", _TownSpotLanded)
		var pos = g.position
		sc.position = pos
		g.replace_by(sc)
		sc.SetSpotData(spottype)
		#if (spottype.GetEnumString() == "CITY_CENTER"):
			#centername = sc.SpotName + " City"
		#else : if (spottype.FullName == "Village"):
			#centername = sc.SpotName
		#else :
			#sc.SpotName = spottype.FullName
		
		
		g.free()
	pass
func SpawnEnemies():
	for g in $CitySpots.get_children() :
		var spot = g as MapSpot
		if (spot.SpotInfo.HostilePatrolShipScene != null):
			spot.SpawnEnemyPatrol()
		if (spot.SpotInfo.HostileShipScene != null):
			spot.SpawnEnemyGarison()
func GetSaveData() -> TownSaveData:
	var datas = TownSaveData.new().duplicate()
	datas.TownLoc = position
	datas.TownRot = rotation
	datas.TownScene = scene_file_path
	var spotdata : Array[MapSpotSaveData]
	for g in $CitySpots.get_children() :
		var spot = g as MapSpot
		spotdata.append(spot.GetSaveData())
	datas.Spots = spotdata
	return datas

#TODO get rid of cities, useless
func GetCityName() -> String:
	var CityName
	for g in $CitySpots.get_children():
		var cit = g as MapSpot
		CityName = cit.SpotName
	return CityName
func LoadSaveData(Dat : TownSaveData) -> void:
	position = Dat.TownLoc
	rotation = Dat.TownRot
	for g in Dat.Spots.size():
		var spotdat = Dat.Spots[g] as MapSpotSaveData
		var sc = SpotScene.instantiate() as MapSpot
		sc.connect("SpotAproached", _TownSpotApreached)
		sc.connect("SpotLanded", _TownSpotLanded)
		
		sc.SetSpotData(spotdat.SpotType)
		
		var spt = $CitySpots.get_child(g)
		spt.replace_by(sc)
		
		sc.position = spt.position
		sc.SpotInfo = spt.SpotInfo
		sc.PlayerFuelReserves = spotdat.PlayerFuelReserves
		sc.CityFuelReserves = spotdat.CityFuelReserves
		spt.free()

		if (spotdat.Seen):
			sc.OnSpotSeen(false)
		
		#sc.Visited = spotdat.Visited
		if (spotdat.Visited):
			sc.Visited = true
			
		#if (spotdat.Analyzed):
			#sc.OnSpotAnalyzed(false)
		
func _TownSpotApreached(spot : MapSpot):
	TownSpotAproached.emit(spot)
#func TownSpotSearched(spot : MapSpot):
	#SpotSearched.emit(spot)
#func _TownSpotAnalyzed(spot : MapSpot):
	#TownSpotAnalazyed.emit(spot)
func _TownSpotLanded(spot : MapSpot):
	TownSpotLanded.emit(spot)

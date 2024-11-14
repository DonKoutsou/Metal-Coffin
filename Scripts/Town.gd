extends Node2D
class_name Town

@export var SpotScene: PackedScene


var LoadingData : bool = false

signal SpotAproached(spot : MapSpot)
signal SpotSearched(spot : MapSpot)
signal SpotAnalazyed(spot : MapSpot)


func _ready() -> void:
	if (!LoadingData):
		rotation = randf_range(0, 360)
		GenerateCity()
	
func GenerateCity() -> void:
	var spots = $CitySpots.get_children()
	for g in spots:
		var spt = g as CitySpot
		var spottype = spt.MapSpotTypes.pick_random()
		var sc = SpotScene.instantiate() as MapSpot
		
		sc.connect("SpotAproached", TownSpotApreached)
		sc.connect("SpotSearched", TownSpotSearched)
		sc.connect("SpotAnalazyed", TownSpotAnalyzed)
		
		sc.SetSpotData(spottype)
		var pos = g.position
		g.replace_by(sc)
		sc.position = pos
		g.free()
	pass

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
func LoadSaveData(Dat : TownSaveData) -> void:
	position = Dat.TownLoc
	rotation = Dat.TownRot
	for g in Dat.Spots.size():
		var spotdat = Dat.Spots[g] as MapSpotSaveData
		var sc = SpotScene.instantiate() as MapSpot
		sc.connect("SpotAproached", TownSpotApreached)
		sc.connect("SpotSearched", TownSpotSearched)
		sc.connect("SpotAnalazyed", TownSpotAnalyzed)
		var type = spotdat.SpotType
		sc.SetSpotData(type)

		if (spotdat.Seen):
			sc.OnSpotSeen(false)
		
		sc.Visited = spotdat.Visited
		
		if (spotdat.Analyzed):
			sc.OnSpotAnalyzed()
		
		var spt = $CitySpots.get_child(g)
		var sptpos = spt.position
		spt.replace_by(sc)
		sc.position = sptpos
		sc.SpotName = spotdat.SpotName
		sc.Evnt = spotdat.Evnt
		spt.free()
		
func TownSpotApreached(spot : MapSpot):
	SpotAproached.emit(spot)
func TownSpotSearched(spot : MapSpot):
	SpotSearched.emit(spot)
func TownSpotAnalyzed(spot : MapSpot):
	SpotAnalazyed.emit(spot)

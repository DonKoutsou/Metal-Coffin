extends Node

class_name SaveLoadManager

static var Instance : SaveLoadManager

func _ready() -> void:
	Instance = self
static func GetInstance() -> SaveLoadManager:
	return Instance

# Called when the node enters the scene tree for the first time.
func Save(world : World) -> void:
	var Mapz = world.GetMap() as Map
	var Inv = world.GetInventory() as Inventory
	var DataArray : Array[Resource] = []
	DataArray.append(Mapz.GetSaveData())
	DataArray.append(Inv.GetSaveData())
	DataArray.append(world.ShipDat.GetSaveData())
	
	var pldata = PlayerSaveData.new()
	pldata.Pos = Mapz.GetPlayerPos()
	DataArray.append(pldata)
	
	var sav = SaveData.new()
	sav.DataName = "Save"
	sav.Datas = DataArray
	ResourceSaver.save(sav, "user://SavedGame.tres")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func Load(world : World) ->bool:
	if (!FileAccess.file_exists("user://SavedGame.tres")):
		return false
	
	var sav = load("user://SavedGame.tres") as SaveData
	var Mapz = world.GetMap() as Map
	var Inv = world.GetInventory() as Inventory
	var mapdata : Array[Resource] = (sav.GetData("MapSpots") as SaveData).Datas
	var InvData : Array[Resource] = (sav.GetData("InventoryContents") as SaveData).Datas
	var StatData : Resource = sav.GetData("Stats")
	Mapz.LoadSaveData(mapdata)
	Inv.LoadSaveData(InvData)
	Mapz.SetPlayerPos(sav.GetData("PLData").Pos)
	call_deferred("LoadStats", world, StatData)
	return true
	#world.LoadData(StatData)
func LoadStats(world : World, StatData : Resource) -> void:
	world.LoadData(StatData)

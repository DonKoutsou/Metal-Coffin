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
	DataArray.append(Mapz.GetEnemySaveData())
	DataArray.append(Mapz.GetMissileSaveData())
	DataArray.append(Inv.GetSaveData())
	DataArray.append(world.ShipDat.GetSaveData())
	DataArray.append(world.GetShipSaveData())
	var pldata = PlayerSaveData.new()
	pldata.Pos = Mapz.GetPlayerPos()
	pldata.DroneDat = PlayerShip.GetInstance().GetDroneDock().GetSaveData()
	DataArray.append(pldata)
	DataArray.append(DialogueProgressHolder.GetInstance().ToldDialogues)
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
	var DiagHolder = world.GetDialogueProgress()
	var mapdata : Array[Resource] = (sav.GetData("Towns") as SaveData).Datas
	var InvData : Array[Resource] = (sav.GetData("InventoryContents") as SaveData).Datas
	var StatData : Resource = sav.GetData("Stats")
	var ShipDat : BaseShip = (sav.GetData("Ship") as SaveData).Datas[0]
	DiagHolder.ToldDialogues =  sav.GetData("SpokenDiags") as SpokenDialogueEntry
	world.StartingShip = ShipDat
	Mapz.LoadSaveData(mapdata)
	Inv.LoadSaveData(InvData)
	Mapz.SetPlayerPos(sav.GetData("PLData").Pos)
	
	var enems : Array[Resource] = (sav.GetData("Enemies") as SaveData).Datas
	var misses : Array[Resource] = (sav.GetData("Missiles") as SaveData).Datas
	world.Loading = true
	call_deferred("LoadStats", world, StatData)
	call_deferred("LoadCaptains", sav.GetData("PLData").DroneDat)
	call_deferred("RespawnEnems", Mapz,enems)
	call_deferred("RespawnMissiles", Mapz,misses)
	return true
	#world.LoadData(StatData)
func LoadStats(world : World, StatData : Resource) -> void:
	world.LoadData(StatData)
func LoadCaptains(DroneDat : Array[DroneSaveData]):
	var dock = PlayerShip.GetInstance().GetDroneDock()
	dock.LoadSaveData(DroneDat)
func RespawnEnems(Mp : Map, Enems : Array[Resource]):
	Mp.RespawnEnemies( Enems )
func RespawnMissiles(Mp : Map, Missiles : Array[Resource]):
	Mp.RespawnMissiles( Missiles )

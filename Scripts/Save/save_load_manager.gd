extends Node

class_name SaveLoadManager

static var Instance : SaveLoadManager

func _ready() -> void:
	Instance = self
static func GetInstance() -> SaveLoadManager:
	return Instance

# Called when the node enters the scene tree for the first time.
func Save() -> void:
	var world = World.GetInstance()
	var Mapz = world.GetMap() as Map
	var Inv = Mapz.GetInScreenUI().GetInventory() as InventoryManager
	var DataArray : Array[Resource] = []
	DataArray.append(world.GetSaveData())
	DataArray.append(Mapz.GetSaveData())
	DataArray.append(Mapz.GetMapMarkerEditorSaveData())
	DataArray.append(Mapz.GetEnemySaveData())
	DataArray.append(Mapz.GetMissileSaveData())
	DataArray.append(Inv.GetSaveData())
	#DataArray.append(world.ShipDat.GetSaveData())
	#DataArray.append(world.GetShipSaveData())
	DataArray.append(world.GetCommander().GetSaveData())
	var pldata = PlayerSaveData.new()
	var Ships = get_tree().get_nodes_in_group("Ships")
	pldata.DroneDat = Ships[0].GetDroneDock().GetSaveData()
	DataArray.append(pldata)
	pldata.Pos = Ships[0].global_position
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
	#var Inv = Mapz.GetInScreenUI().GetInventory() as InventoryManager
	var DiagHolder = world.GetDialogueProgress()
	var mapdata : Array[Resource] = (sav.GetData("Towns") as SaveData).Datas
	var WalletData : Wallet = (sav.GetData("Wallet") as SaveData).Datas[0]
	var InvData : SaveData = sav.GetData("InventoryContents") as SaveData
	#var StatData : Resource = sav.GetData("Stats")
	#var ShipDat : BaseShip = (sav.GetData("Ship") as SaveData).Datas[0]
	DiagHolder.ToldDialogues =  sav.GetData("SpokenDiags") as SpokenDialogueEntry
	#world.StartingShip = ShipDat
	Mapz.LoadSaveData(mapdata)
	
	var enems : Array[Resource] = (sav.GetData("Enemies") as SaveData).Datas
	var misses : Array[Resource] = (sav.GetData("Missiles") as SaveData).Datas
	var MarkerEditorData : SD_MapMarkerEditor = (sav.GetData("MarkerEditor") as SaveData).Datas[0]
	var InvestigationPositions = sav.GetData("PositionsToInvestigate") as SaveData
	world.Loading = true
	#call_deferred("LoadStats", world, StatData)
	call_deferred("LoadMapDat", world, WalletData, sav.GetData("PLData").Pos ,sav.GetData("PLData").DroneDat, enems, misses, MarkerEditorData, InvestigationPositions, InvData)
	return true

func LoadMapDat(W : World, PlayerWallet : Wallet, PlPos : Vector2, DroneDat : Array[DroneSaveData], Enems : Array[Resource], Missiles : Array[Resource], Data : SD_MapMarkerEditor, InvestigationData : SaveData, InvData : SaveData) -> void:
	await W.WRLD_WorldReady
	var Mp = W.GetMap()
	var Ships = get_tree().get_nodes_in_group("Ships")
	Ships[0].GetDroneDock().LoadSaveData(DroneDat)
	Ships[0].global_position = PlPos
	W.LoadSaveData(PlayerWallet)
	Mp.RespawnEnemies( Enems )
	Mp.RespawnMissiles( Missiles )
	Mp.LoadMapMarkerEditorSaveData(Data)
	W.GetCommander().LoadSaveData(InvestigationData)
	Mp.GetInScreenUI().GetInventory().LoadSaveData(InvData)

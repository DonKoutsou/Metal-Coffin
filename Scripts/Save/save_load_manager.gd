extends Node

class_name SaveLoadManager

static var Instance : SaveLoadManager

func _ready() -> void:
	Instance = self
static func GetInstance() -> SaveLoadManager:
	return Instance

func DeleteSave() -> void:
	DirAccess.remove_absolute("user://SavedGame.tres")
	DirAccess.remove_absolute("user://PrologueSavedGame.tres")
	TutorialManager.GetInstance().DeleteSave()

static func SaveExists(Sav : String) -> bool:
	var CurrentVersion = ProjectSettings.get_setting("application/config/version")
		
	if (!FileAccess.file_exists(Sav)):
		return false
	
	var sav = load(Sav) as SaveData
	
	if (sav == null):
		return false
	
	if (sav.GameVersion != CurrentVersion):
		return false
	
	return true

# Called when the node enters the scene tree for the first time.
func Save() -> void:
	var world = World.GetInstance()
	#if (world.IsPrologue):
		#PopUpManager.GetInstance().DoPopUp("Can't save progress in prologue.")
		#return
	var Mapz = world.GetMap() as Map
	var Inv = InventoryManager.GetInstance()
	var Controller = world.Controller
	var DataArray : Array[Resource] = []
	DataArray.append(world.GetSaveData())
	DataArray.append(Mapz.GetSaveData())
	DataArray.append(Mapz.GetMapMarkerEditorSaveData())
	DataArray.append(WeatherManage.GetInstance().GetSaveData())
	DataArray.append(Mapz.GetMissileSaveData())
	
	DataArray.append(Inv.GetSaveData())
	
	#DataArray.append(world.ShipDat.GetSaveData())
	#DataArray.append(world.GetShipSaveData())
	DataArray.append(world.GetCommander().GetEnemySaveData())
	DataArray.append(world.GetCommander().GetSaveData())
	
	DataArray.append(Controller.GetSaveData())
	
	DataArray.append(MapPointerManager.GetInstance().GetSaveData())
	
	DataArray.append(Clock.GetInstance().GetSaveData())
	
	ActionTracker.Save()
	
	DataArray.append(DialogueProgressHolder.GetInstance().ToldDialogues)
	var sav = SaveData.new()
	sav.DataName = "Save"
	sav.Datas = DataArray
	sav.GameVersion = ProjectSettings.get_setting("application/config/version")
	
	var SaveName : String
	
	WorldView.SaveWorldview()
	
	if (world.IsPrologue):
		SaveName = "user://PrologueSavedGame.tres"
	else:
		SaveName = "user://SavedGame.tres"
	
	ResourceSaver.save(sav, SaveName)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func Load(world : World) ->Dictionary:
	var Resaults : Dictionary
	var CurrentVersion = ProjectSettings.get_setting("application/config/version")
	
	var SaveName : String
	if (world.IsPrologue):
		SaveName = "user://PrologueSavedGame.tres"
	else:
		SaveName = "user://SavedGame.tres"
		
	if (!FileAccess.file_exists(SaveName)):
		Resaults["Succsess"] = false
		Resaults["Reason"] = "Save file could not be found."
		return Resaults
	
	var sav = load(SaveName) as SaveData
	
	if (sav == null):
		Resaults["Succsess"] = false
		Resaults["Reason"] = "Couldn't load save."
		return Resaults
	
	if (sav.GameVersion != CurrentVersion):
		Resaults["Succsess"] = false
		Resaults["Reason"] = "Game Version doesen't match save file.\nSave File Version = {0}".format([sav.GameVersion])
		return Resaults
	
	
	
	var Mapz = world.GetMap() as Map
	var DiagHolder = world.GetDialogueProgress()
	var mapdata : Array[Resource] = (sav.GetData("Towns") as SaveData).Datas
	DiagHolder.ToldDialogues =  sav.GetData("SpokenDiags") as SpokenDialogueEntry
	Mapz.LoadSaveData(mapdata)

	world.Loading = true

	call_deferred("LoadMapDat", sav)
	Resaults["Succsess"] = true
	return Resaults

func LoadMapDat(Data : SaveData) -> void:
	var W = World.GetInstance()
	await W.WRLD_WorldReady
	var Mp = W.GetMap()
	#var Ships = get_tree().get_nodes_in_group("Ships")
	var Controller = W.Controller
	Controller.LoadSaveData(Data.GetData("PLData"))
	W.LoadSaveData((Data.GetData("Wallet") as SaveData).Datas[0])
	Mp.RespawnEnemies((Data.GetData("Enemies") as SaveData).Datas)
	Mp.RespawnMissiles((Data.GetData("Missiles") as SaveData).Datas)
	#await Mp.GenerationFinished
	Mp.LoadMapMarkerEditorSaveData((Data.GetData("MarkerEditor") as SaveData).Datas[0])
	W.GetCommander().LoadSaveData(Data.GetData("PositionsToInvestigate") as SaveData)
	Mp.GetInScreenUI().GetInventory().LoadSaveData(Data.GetData("InventoryContents") as SaveData)
	Clock.GetInstance().LoadData(Data.GetData("Clock") as SaveData)
	WeatherManage.GetInstance().LoadSaveData((Data.GetData("Weather") as SaveData).Datas[0])

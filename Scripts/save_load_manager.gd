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
	var sav = SaveData.new()
	sav.DataName = "Save"
	sav.Datas = DataArray
	ResourceSaver.save(sav, "user://SavedGame.tres")
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

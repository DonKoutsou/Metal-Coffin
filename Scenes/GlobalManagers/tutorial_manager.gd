extends CanvasLayer

class_name ActionTracker

@export var TutorialScene : PackedScene
@export var OutTutorialScene : PackedScene

static var CompletedActions : Array[Action]

static var Instance : ActionTracker

static var ShowTutorials : bool = false

func _ready() -> void:
	Instance = self
	Load()

static func GetInstance() -> ActionTracker:
	return Instance

static func IsActionCompleted(Act : Action) -> bool:
	return CompletedActions.has(Act)

static func OnActionCompleted(Act : Action) -> void:
	CompletedActions.append(Act)


func ShowTutorial(TurotialTitle : String, TutorialText : String, ElementsToFocusOn : Array[Control], _InScreen : bool) -> void:
	if (!ShowTutorials):
		return
	
	get_tree().paused = true

	var Tut : Tutorial
	
	#if (InScreen):
		#Tut = TutorialScene.instantiate() as Tutorial
	#else:
	Tut = OutTutorialScene.instantiate() as Tutorial
	
	Tut.SetData(TurotialTitle, TutorialText, ElementsToFocusOn)
	
	#if (InScreen):
		#Ingame_UIManager.GetInstance().AddUI(Tut, false, true)
	#else:
	add_child(Tut)
	
	await Tut.Completed
	
	get_tree().paused = false

func DidPrologue() -> bool:
	if (!FileAccess.file_exists("user://TutorialData.tres")):
		return false
	
	var sav = load("user://TutorialData.tres") as TutorialSaveData
	
	if (sav == null):
		return false
	
	return sav.CompletedPrologue

func GetPrologueCaptains() -> Array[String]:

	var sav = load("user://TutorialData.tres") as TutorialSaveData

	return sav.CaptainsInPrologue

func OnPrologueFinished() -> void:
	var sav = load("user://TutorialData.tres") as TutorialSaveData
	
	var C : Array[String]
	
	for Ship : PlayerDrivenShip in get_tree().get_nodes_in_group("PlayerShips"):
		if (Ship is PlayerShip):
			continue
		C.append(Ship.Cpt.resource_path)
	
	sav.CaptainsInPrologue = C
	sav.CompletedPrologue = true
	sav.WorldviewStats = WorldView.GetInstance().WorldviewStats
	sav.LiedInPrologue = WorldView.GetInstance().Lied
	ResourceSaver.save(sav, "user://TutorialData.tres")
	print("Saved Fulfilled Prologue data")

static func Save() -> void:
	var sav : TutorialSaveData
	
	if (FileAccess.file_exists("user://TutorialData.tres")):
		sav = load("user://TutorialData.tres") as TutorialSaveData
	
	if (sav == null):
		sav = TutorialSaveData.new()
	
	sav.CompletedActions.clear()
	
	sav.CompletedActions = CompletedActions

	ResourceSaver.save(sav, "user://TutorialData.tres")
	print("Saved tutorial data")

func Load() -> void:
	CompletedActions.clear()
	
	if (!FileAccess.file_exists("user://TutorialData.tres")):
		return
	
	var sav = load("user://TutorialData.tres") as TutorialSaveData
	
	if (sav == null):
		return
	
	print("Loaded found tutorial data")
	
	CompletedActions = sav.CompletedActions

func DeleteSave() -> void:
	var sav : TutorialSaveData
	
	if (FileAccess.file_exists("user://TutorialData.tres")):
		sav = load("user://TutorialData.tres") as TutorialSaveData
	
	if (sav == null):
		return

	sav.CompletedActions.clear()
	sav.CompletedPrologue = false
	
	ResourceSaver.save(sav, "user://TutorialData.tres")
	

enum Action{
	INVENTORY_OPEN,
	ITEM_INSPECTION,
	STEER,
	CAMERA_CONTROL,
	TOWN_APROACH,
	ENEMY_TOWN_APROACH,
	CARD_FIGHT,
	CARD_FIGHT_ACTION_PICK,
	CARD_FIGHT_SPEED_EXPLENATION,
	CARD_FIGHT_ENERGY,
	CARD_FIGHT_RESERVES,
	CARD_FIGHT_ACTION_PERFORM,
	CARD_FIGHT_TARGET_PICKING,
	CARD_FIGHT_SHIPLOSS,
	CARD_FIGHT_HAND_LIMIT,
	ELINT_CONTACT,
	LANDING,
	TOWN_SHOP,
	FUEL_SHOP,
	REPAIR_SHOP,
	MERCH_SHOP,
	UPGRADE_SHOP,
	FLEET_SEPARATION,
	MISSILE_LAUNCH,
	HAPPENING,
	RECRUIT,
	WORLDVIEW_CHECK,
	GARISSION_ALARM,
	CONVOY,
	SIMULATION,
	MAP_MARKER,
	MAP_MARKER_INTRO,
}

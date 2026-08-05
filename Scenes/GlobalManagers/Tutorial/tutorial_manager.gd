extends CanvasLayer

class_name ActionTracker

@export var TutorialScene : PackedScene
@export var OutTutorialScene : PackedScene
@export_file("*.tres") var TutorialTexts : PackedStringArray

static var TutorialArgs : Dictionary[Action, PackedStringArray]
static var CompletedActions : Array[Action]

static var Instance : ActionTracker

static var ShowTutorials : bool = false


var ShowingTutorial : bool = false

static var QueuedTutorials : Array[Action]

func _ready() -> void:
	Instance = self
	Load()

static func GetInstance() -> ActionTracker:
	return Instance

static func IsActionCompleted(Act : Action) -> bool:
	return Act in CompletedActions

static func OnActionCompleted(Act : Action) -> void:
	CompletedActions.append(Act)

func _physics_process(_delta: float) -> void:
	if (World.WORLDST != World.WORLDSTATE.INITIAL and !ShowingTutorial and !TransitionPanel.Transitioning):
		if QueuedTutorials.size() > 0:
			var act = QueuedTutorials[0]
			var nexttut : TutorialData = load(TutorialTexts[act])
			if (TargetsExists(nexttut.Target)):
				var title : String = nexttut.Title
				var text : String = nexttut.Text
				
				if (TutorialArgs.has(act)): #check if we have arguments to place into the string
					text.format(TutorialArgs[act])
					TutorialArgs.erase(act)

				text = TranslationServer.translate(text)
				
				ShowTutorial(title, text, nexttut.Target)
				QueuedTutorials.pop_front()

static func QueueTutorial(Turotial : Action, Args : PackedStringArray = []) -> void:
	if (!ShowTutorials):
		return
	if (Args.size() > 0):
		TutorialArgs[Turotial] = Args
	QueuedTutorials.append(Turotial)

func ShowTutorial(TurotialTitle : String, TutorialText : String, ElementsToFocusOn : Array[ScreenUI.UI_ELEMENT]) -> void:
	get_tree().paused = true
	
	ShowingTutorial = true

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
	
	ShowingTutorial = false
	
	

func TargetsExists(Elements : Array[ScreenUI.UI_ELEMENT]) -> bool:
	for g in Elements:
		if (!ScreenUI.Instance.UIElementExists(g)):
			return false
	return true

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
	INVENTORY_OPEN = 0,
	ITEM_INSPECTION = 1,
	STEER = 2,
	CAMERA_CONTROL = 3,
	TOWN_APROACH = 4,
	ENEMY_TOWN_APROACH = 5,
	CARD_FIGHT = 6,
	CARD_FIGHT_ACTION_PICK = 7,
	CARD_FIGHT_SPEED_EXPLENATION = 8,
	CARD_FIGHT_ENERGY = 9,
	CARD_FIGHT_RESERVES = 10,
	CARD_FIGHT_ENEMY_ACTION_PERFORM = 11,
	CARD_FIGHT_TARGET_PICKING = 12,
	CARD_FIGHT_SHIPLOSS = 13,
	CARD_FIGHT_HAND_LIMIT = 14,
	ELINT_CONTACT = 15,
	LANDING = 16,
	TOWN_SHOP = 17,
	FUEL_SHOP = 18,
	REPAIR_SHOP = 19,
	MERCH_SHOP = 20,
	UPGRADE_SHOP = 21,
	FLEET_SEPARATION = 22,
	MISSILE_LAUNCH = 23,
	HAPPENING = 24,
	RECRUIT = 25,
	WORLDVIEW_CHECK = 26,
	GARISSION_ALARM = 27,
	CONVOY = 28,
	SIMULATION = 29,
	MAP_MARKER = 30,
	MAP_MARKER_INTRO = 31,
	MISSILE_TOGGLE = 32,
	MISSILE_ARM = 33,
	MISSILE_SELECT_NUM = 34,
	HATCH = 35,
	ELEVATION = 36,
	AEROSONAR = 37,
	CARD_FIGHT_OUTNUMER_BONUS = 38,
	CARD_FIGHT_CARD_RECYCLE = 39,
}

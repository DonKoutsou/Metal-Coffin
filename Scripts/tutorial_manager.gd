extends CanvasLayer

class_name ActionTracker

@export var TutorialScene : PackedScene

static var CompletedActions : Array[Action]

static var Instance : ActionTracker

func _ready() -> void:
	Instance = self
	Load()

static func GetInstance() -> ActionTracker:
	return Instance

static func IsActionCompleted(Act : Action) -> bool:
	return CompletedActions.has(Act)

static func OnActionCompleted(Act : Action) -> void:
	CompletedActions.append(Act)
	Save()

func ShowTutorial(TurotialTitle : String, TutorialText : String, ElementsToFocusOn : Array[Control], InScreen : bool) -> void:
	get_tree().paused = true
	
	var di : Dictionary[int, float] = {
		1 : 0.3,
		3 : 0.4
	}
	var Tut = TutorialScene.instantiate() as Tutorial
	
	Tut.SetData(TurotialTitle, TutorialText, ElementsToFocusOn)
	
	if (InScreen):
		Ingame_UIManager.GetInstance().AddUI(Tut, false, true)
	else:
		add_child(Tut)
	
	await Tut.Completed
	
	get_tree().paused = false

static func Save() -> void:
	var sav = TutorialSaveData.new()
	sav.CompletedActions = CompletedActions.duplicate()
	ResourceSaver.save(sav, "user://TutorialData.tres")
	print("Saved tutorial data")

func Load() -> void:
	if (!FileAccess.file_exists("user://TutorialData.tres")):
		return
	
	var sav = load("user://TutorialData.tres") as TutorialSaveData
	
	if (sav == null):
		return
	
	print("Loaded found tutorial data")
	
	CompletedActions = sav.CompletedActions

enum Action{
	INVENTORY_OPEN,
	ITEM_INSPECTION,
	STEER,
	ACCELERATE,
	TOWN_APROACH,
	ENEMY_TOWN_APROACH,
	CARD_FIGHT,
	ELINT_CONTACT,
	LANDING,
	TOWN_SHOP,
	MISSILE_LAUNCH,
	HAPPENING,
	
}

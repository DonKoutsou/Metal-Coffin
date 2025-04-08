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

	var Tut = TutorialScene.instantiate() as Tutorial
	
	Tut.SetData(TurotialTitle, TutorialText, ElementsToFocusOn)
	
	if (InScreen):
		Ingame_UIManager.GetInstance().AddUI(Tut, false, true)
	else:
		add_child(Tut)
	
	await Tut.Completed
	
	get_tree().paused = false

static func Save() -> void:
	var sav : TutorialSaveData
	
	if (FileAccess.file_exists("user://TutorialData.tres")):
		sav = load("user://TutorialData.tres") as TutorialSaveData
	
	if (sav == null):
		sav = TutorialSaveData.new()
	
	for g in CompletedActions:
		if (!sav.CompletedActions.has(g)):
			sav.CompletedActions.append(g)

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
	DirAccess.remove_absolute("user://TutorialData.tres")
	Load()

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
	RECRUIT,
	WORLDVIEW_CHECK
}

extends CanvasLayer

class_name ActionTracker

@export var TutorialScene : PackedScene

static var CompletedActions : Array[Action]

static var Instance : ActionTracker

func _ready() -> void:
	Instance = self

static func GetInstance() -> ActionTracker:
	return Instance

static func IsActionCompleted(Act : Action) -> bool:
	return CompletedActions.has(Act)

static func OnActionCompleted(Act : Action) -> void:
	CompletedActions.append(Act)

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

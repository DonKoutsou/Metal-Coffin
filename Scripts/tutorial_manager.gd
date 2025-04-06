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

func ShowTutorial(TurotialTitle : String, TutorialText : String, ElementToFocusOn : Control, InScreen : bool) -> void:
	var di : Dictionary[int, float] = {
		1 : 0.3,
		3 : 0.4
	}
	var Tut = TutorialScene.instantiate() as Tutorial
	
	Tut.SetData(TurotialTitle, TutorialText, ElementToFocusOn)
	
	if (InScreen):
		Ingame_UIManager.GetInstance().AddUI(Tut, false, true)
	else:
		add_child(Tut)



enum Action{
	INVENTORY_OPEN,
	ITEM_INSPECTION,
	TOWN_APROACH,
	CARD_FIGHT
}

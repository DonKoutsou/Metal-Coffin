extends Resource

class_name TutorialSaveData

@export var CompletedActions : Array[ActionTracker.Action]
@export var CompletedPrologue : bool = false
@export var WorldviewStats : Dictionary[WorldView.WorldViews, int] = {
	WorldView.WorldViews.COMPOSURE_AGITATION : 0,
	WorldView.WorldViews.LOGIC_BELIEF : 0,
	WorldView.WorldViews.EMPATHY_EGO : 0,
	WorldView.WorldViews.FORCE_INSPIRATION : 0,
	WorldView.WorldViews.MAN_MACHINE : 0,
}

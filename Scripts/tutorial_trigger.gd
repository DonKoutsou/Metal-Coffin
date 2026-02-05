extends Node2D

class_name TutTrigger

@export var TutorialToShow : ActionTracker.Action
@export var TutorialTitle : String
@export_multiline var TutorialText : String
@export var TutorialElement : Array[Map.UI_ELEMENT]
@export var Inscreen : bool

func _on_area_2d_area_entered(area: Area2D) -> void:
	if (area.get_parent() is PlayerDrivenShip):
		if (!ActionTracker.IsActionCompleted(TutorialToShow)):
			ActionTracker.OnActionCompleted(TutorialToShow)
			ActionTracker.GetInstance().ShowTutorial(TutorialTitle, TutorialText, TutorialElement, Inscreen)
		queue_free()

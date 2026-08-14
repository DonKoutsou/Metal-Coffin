extends Node2D

class_name TutTrigger

@export var TutorialToShow : ActionTracker.Action
@export var Inscreen : bool

func _on_area_2d_area_entered(area: Area2D) -> void:
	if (area.get_parent() is PlayerDrivenShip):
		ActionTracker.OnActionCompleted(TutorialToShow)
		queue_free()

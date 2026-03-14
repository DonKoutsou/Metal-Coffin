extends Node2D

class_name PrologueEnd_Trigger

@export_multiline var OutroText : Array[String]

func _on_area_2d_area_entered(area: Area2D) -> void:
	if (area.get_parent() is PlayerDrivenShip):
		Ingame_UIManager.GetInstance().CallbackDiag(OutroText, null, "", DialogueEnded, true)

func DialogueEnded() -> void:
	World.GetInstance().EndPrologue()

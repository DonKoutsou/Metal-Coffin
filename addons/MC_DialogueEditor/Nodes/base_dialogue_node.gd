@tool
extends GraphNode

class_name BaseDialogueNode

signal Changed

func _on_delete_request() -> void:
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	hide()


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	show()

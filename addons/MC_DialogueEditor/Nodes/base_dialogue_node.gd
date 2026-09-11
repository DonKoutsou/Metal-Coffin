@tool
extends GraphNode

class_name BaseDialogueNode

signal Changed

func _on_delete_request() -> void:
	queue_free()

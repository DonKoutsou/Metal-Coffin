@tool
extends GraphNode

class_name BaseDialogueNode

@export var textInput : TextEdit

func AddText(text : String) -> void:
	textInput.text = text

func _on_delete_request() -> void:
	queue_free()

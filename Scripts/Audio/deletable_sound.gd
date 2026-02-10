extends AudioStreamPlayer2D

class_name DeletableSound

signal Deleted

func _ready() -> void:
	connect("finished", _on_finished)

func _on_finished() -> void:
	queue_free()

func _exit_tree() -> void:
	Deleted.emit()

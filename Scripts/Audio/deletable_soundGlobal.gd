extends AudioStreamPlayer

class_name DeletableSoundGlobal

func _ready() -> void:
	connect("finished", _on_finished)

func _on_finished() -> void:
	queue_free()

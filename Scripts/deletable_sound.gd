extends AudioStreamPlayer2D

class_name DeletableSound

func _on_finished() -> void:
	queue_free()

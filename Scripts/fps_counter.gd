extends Label

func _physics_process(_delta: float) -> void:
	text = var_to_str(Engine.get_frames_per_second())

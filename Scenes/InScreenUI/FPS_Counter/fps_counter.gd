extends Label

func _physics_process(_delta: float) -> void:
	text = "FPS : {0}".format([var_to_str(roundi(Engine.get_frames_per_second()))])

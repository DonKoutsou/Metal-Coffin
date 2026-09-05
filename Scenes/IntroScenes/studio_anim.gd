extends IntroScene

class_name StudioAnimation

func _ready() -> void:
	$AnimationPlayer.play("LogoDraw")
	$AnimationPlayer.animation_finished.connect(AnimFinished)

func AnimFinished() -> void:
	Finished.emit()
	queue_free()

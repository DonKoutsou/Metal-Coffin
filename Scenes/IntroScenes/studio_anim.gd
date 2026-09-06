extends IntroScene

class_name StudioAnimation

func _ready() -> void:
	$AnimationPlayer.play("LogoDraw")

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	Finished.emit()
	queue_free()

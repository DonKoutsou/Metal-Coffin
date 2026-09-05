extends Control

class_name IntroScene

signal Finished

func _ready() -> void:
	modulate.a = 0
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color(1,1,1,1), 1)
	
	get_tree().create_timer(3).timeout.connect(FadeInEnded)

func FadeInEnded() -> void:
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color(1,1,1,0), 1)
	tw.finished.connect(FadeOutEnded)

func FadeOutEnded() -> void:
	Finished.emit()
	queue_free()

func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("Pause")):
		Finished.emit()
		queue_free()

extends ProgressBar

class_name AtackTimer

@export var Timeout : float = 8
@export var T : Timer
@export var S : AudioStreamPlayer
@export var Text : Label

signal Finished

func _ready() -> void:
	T.wait_time = Timeout
	max_value = Timeout
	value = Timeout
	T.start()

func _physics_process(delta: float) -> void:
	value = T.time_left
	Text.text = var_to_str(roundi(value)) + " s"
	if (value <= 3 and !S.playing):
		S.play()
	
func _on_timer_timeout() -> void:
	Finished.emit()

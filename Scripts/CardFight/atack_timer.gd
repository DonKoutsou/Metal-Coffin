extends ProgressBar

class_name AtackTimer

@export var Timeout : float = 8

signal Finished

func _ready() -> void:
	$Timer.wait_time = Timeout
	max_value = Timeout
	value = Timeout
	$Timer.start()

func _physics_process(delta: float) -> void:
	value = $Timer.time_left

func _on_timer_timeout() -> void:
	Finished.emit()

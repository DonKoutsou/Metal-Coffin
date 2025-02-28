extends Label

class_name Floater
@onready var timer: Timer = $Timer

signal Ended
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer.start()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	position.y -= 2
	pass


func _on_timer_timeout() -> void:
	Ended.emit()
	queue_free()
	pass # Replace with function body.

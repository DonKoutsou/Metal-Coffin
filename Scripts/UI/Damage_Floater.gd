extends Label

class_name Floater


@export var GoodColor : Color
@export var BadColor : Color
@export var EndTimer : Timer


signal Ended
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EndTimer.start()
	pass # Replace with function body.

func SetColor(Good : bool) -> void:
	if (Good):
		modulate = GoodColor
	else:
		modulate = BadColor
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	position.y -= 1
	pass


func _on_timer_timeout() -> void:
	Ended.emit()
	queue_free()
	pass # Replace with function body.

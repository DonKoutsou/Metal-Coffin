extends Label

class_name Floater


@export var GoodColor : Color
@export var BadColor : Color


signal Ended
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	call_deferred("DoThing")

func DoThing() -> void:
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "position", Vector2(position.x, position.y - 40), 0.75)
	await tw.finished
	Ended.emit()
	queue_free()

func SetColor(Good : bool) -> void:
	if (Good):
		modulate = GoodColor
	else:
		modulate = BadColor

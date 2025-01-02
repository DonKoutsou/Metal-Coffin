extends Control

class_name CardOffensiveAnimation

var LinePos : Vector2

func _ready() -> void:
	var tw = create_tween()
	tw.tween_property(self, "LinePos", $DeffensiveCard.position, 1)


func _physics_process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	#draw_set_transform(position)
	draw_line($OffensiveCard.global_position, $DeffensiveCard.global_position, Color(1,1,1,1))

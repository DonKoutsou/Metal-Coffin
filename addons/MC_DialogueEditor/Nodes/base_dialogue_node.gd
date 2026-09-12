@tool
extends GraphNode

class_name BaseDialogueNode

const PORT_LEFT_ICON := preload("res://addons/beehave/debug/icons/port_left.svg")
const PORT_RIGHT_ICON := preload("res://addons/beehave/debug/icons/port_right.svg")

signal Changed

func _on_delete_request() -> void:
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	hide()


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	show()

#func _draw_port(slot_index: int, port_position: Vector2i, left: bool, color: Color) -> void:
	#if is_slot_enabled_left(1):
		#draw_texture(PORT_LEFT_ICON, Vector2(0, size.y / 2) + Vector2(-10, -11), color)
	#if is_slot_enabled_right(1):
		#draw_texture(PORT_RIGHT_ICON, Vector2(size.x, size.y / 2) + Vector2(-9, -11), color)
#
#func get_output_port_position(port : int) -> Vector2:
	#return Vector2(0, size.y / 2)
#
#
#func get_input_port_position(port : int) -> Vector2:
	#return Vector2(size.x, size.y / 2)

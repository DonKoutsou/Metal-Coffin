extends Control

class_name MapMarkerControls

@export var TouchStopper : Control

var Showing = false

signal MarkerHorizontalMove(Amm : float)
signal MarkerVerticalMove(Amm : float)
signal ExitPressed
signal ClearPressed
signal DrawLine
signal DrawText

func _on_y_gas_range_changed(NewVal: float) -> void:
	MarkerHorizontalMove.emit(NewVal)


func _on_x_gas_range_changed(NewVal: float) -> void:
	MarkerVerticalMove.emit(NewVal)


func _on_exit_map_marker_pressed() -> void:
	ExitPressed.emit()


func _on_clear_lines_pressed() -> void:
	ClearPressed.emit()


func _on_draw_line_pressed() -> void:
	DrawLine.emit()


func _on_draw_text_pressed() -> void:
	DrawText.emit()

func Toggle() -> void:
	if ($AnimationPlayer.is_playing()):
		await $AnimationPlayer.animation_finished
	if (!Showing):
		TouchStopper.mouse_filter = MOUSE_FILTER_IGNORE
		$AnimationPlayer.play("Show")
		Showing = true
	else:
		TurnOffPressed()

func TurnOffPressed() -> void:
	TouchStopper.mouse_filter = MOUSE_FILTER_STOP
	$AnimationPlayer.play("Hide")
	Showing = false

func TurnOff() -> void:
	if (!Showing):
		return
	TurnOffPressed()

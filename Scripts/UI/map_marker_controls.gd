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

func _ready() -> void:
	visible = false

func _on_y_gas_range_changed(NewVal: float) -> void:
	MarkerVerticalMove.emit(NewVal)


func _on_x_gas_range_changed(NewVal: float) -> void:
	MarkerHorizontalMove.emit(NewVal)
	

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
		visible = true
		TouchStopper.mouse_filter = MOUSE_FILTER_IGNORE
		$AnimationPlayer.play("Show")
		Showing = true
		await $AnimationPlayer.animation_finished
		
		if (!ActionTracker.IsActionCompleted(ActionTracker.Action.MAP_MARKER_INTRO)):
			ActionTracker.OnActionCompleted(ActionTracker.Action.MAP_MARKER_INTRO)
			ActionTracker.GetInstance().ShowTutorial("Map Marker Editor Controlls", "The [color=#ffc315]Map Marker Editor[/color] provides the creation of texts markers and measuring lines. Use the [color=#ffc315Move Horizontal[/color] and [color=#ffc315]Move Vertical[/color] dials to select the plecement of the marker. Clicking the [color=#ffc315]Text Button[/color] will prompt you with inputing the text that will aprear on the marker. Clicking the [color=#ffc315]Line Button[/color] will start drawing a line, use the dials to extend the line and press the [color=#ffc315]Line Button[/color] again to place the line.", [self], false)
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


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if (anim_name == "Hide"):
		visible = false

extends Control

class_name MapMarkerControls

@export var TouchStopper : Control
@export var EventHandler : UIEventHandler

var Showing = false

func _ready() -> void:
	visible = false


func _on_y_gas_range_changed(NewVal: float) -> void:
	EventHandler.OnMarkerEditorYRangeChanged(NewVal)


func _on_x_gas_range_changed(NewVal: float) -> void:
	EventHandler.OnMarkerEditorXRangeChanged(NewVal)


func _on_exit_map_marker_pressed() -> void:
	EventHandler.OnMarkerEditorToggled(false)
	TurnOff()


func _on_clear_lines_pressed() -> void:
	EventHandler.OnMarkerEditorClearLinesPressed()


func _on_draw_line_pressed() -> void:
	EventHandler.OnMarkerEditorDrawLinePressed()


func _on_draw_text_pressed() -> void:
	EventHandler.OnMarkerEditorDrawTextPressed()


func Toggle() -> void:
	if ($AnimationPlayer.is_playing()):
		return
	if (!Showing):
		visible = true
		TouchStopper.mouse_filter = MOUSE_FILTER_IGNORE
		$AnimationPlayer.play("Show")
		Showing = true
		await $AnimationPlayer.animation_finished
		
		if (!ActionTracker.IsActionCompleted(ActionTracker.Action.MAP_MARKER_INTRO)):
			ActionTracker.OnActionCompleted(ActionTracker.Action.MAP_MARKER_INTRO)
			ActionTracker.GetInstance().ShowTutorial("Map Marker Editor Controlls", "The [color=#ffc315]Map Marker Editor[/color] provides the creation of texts markers and measuring lines. Use the [color=#ffc315]Move Horizontal[/color] and [color=#ffc315]Move Vertical[/color] dials to select the plecement of the marker.\n\nClicking the [color=#ffc315]Text Button[/color] will prompt you with inputing the text that will aprear on the marker.\n\nClicking the [color=#ffc315]Line Button[/color] will start drawing a line, use the dials to extend the line and press the [color=#ffc315]Line Button[/color] again to place the line.", [self], false)
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

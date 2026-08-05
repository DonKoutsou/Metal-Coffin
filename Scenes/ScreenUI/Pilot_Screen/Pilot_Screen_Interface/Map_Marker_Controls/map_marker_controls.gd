extends Control

class_name MapMarkerControls

@export var ToggleButton : Button
@export var EventHandler : UIEventHandler

var Working = false



func _on_y_gas_range_changed(NewVal: float) -> void:
	if (!Working):
		return
	EventHandler.OnMarkerEditorYRangeChanged(NewVal)


func _on_x_gas_range_changed(NewVal: float) -> void:
	if (!Working):
		return
	EventHandler.OnMarkerEditorXRangeChanged(NewVal)

func _on_clear_lines_pressed() -> void:
	if (!Working):
		return
	EventHandler.OnMarkerEditorClearLinesPressed()


func _on_draw_line_pressed() -> void:
	if (!Working):
		return
	EventHandler.OnMarkerEditorDrawLinePressed()


func _on_draw_text_pressed() -> void:
	if (!Working):
		return
	EventHandler.OnMarkerEditorDrawTextPressed()


func Toggle(t : bool) -> void:
	if (!t):
		EventHandler.OnMarkerEditorToggled(false)
		Working = false
	else:
		Working = true
		EventHandler.OnMarkerEditorToggled(true)
		if (!ActionTracker.IsActionCompleted(ActionTracker.Action.MAP_MARKER_INTRO)):
			ActionTracker.OnActionCompleted(ActionTracker.Action.MAP_MARKER_INTRO)
			ActionTracker.QueueTutorial(ActionTracker.Action.MAP_MARKER_INTRO)
	


func _on_exit_map_marker_toggled(toggled_on: bool) -> void:
	Toggle(toggled_on)

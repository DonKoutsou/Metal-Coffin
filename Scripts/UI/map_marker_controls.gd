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


func _on_exit_map_marker_pressed() -> void:
	Toggle()

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


func Toggle() -> void:
	if (Working):
		
		EventHandler.OnMarkerEditorToggled(false)
		Working = false
	else:
		Working = true
		EventHandler.OnMarkerEditorToggled(true)
		if (!ActionTracker.IsActionCompleted(ActionTracker.Action.MAP_MARKER_INTRO)):
			ActionTracker.OnActionCompleted(ActionTracker.Action.MAP_MARKER_INTRO)
			ActionTracker.GetInstance().ShowTutorial("Map Marker Editor Controlls", "The [color=#ffc315]Map Marker Editor[/color] provides the creation of texts markers and measuring lines. Use the [color=#ffc315]Move Horizontal[/color] and [color=#ffc315]Move Vertical[/color] dials to select the plecement of the marker.\n\nClicking the [color=#ffc315]Text Button[/color] will prompt you with inputing the text that will aprear on the marker.\n\nClicking the [color=#ffc315]Line Button[/color] will start drawing a line, use the dials to extend the line and press the [color=#ffc315]Line Button[/color] again to place the line.", [Map.UI_ELEMENT.PILOT_MAP_MARKER_TOGGLE], false)
	

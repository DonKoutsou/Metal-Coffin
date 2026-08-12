extends Control

class_name MapMarkerEditor

@export_group("Nodes")
@export var XLine : Line2D
@export var YLine : Line2D
@export var lineTarget : Panel
@export var textInput : TextEdit
@export var textInputParent : Control
@export var TempLineParent : Node2D
@export_group("Scenes")
@export var LineScene : PackedScene
@export var TextScene : PackedScene


var Line : MapMarkerLine

##we need to know about the camera to update our line distances
var ship_camera: ShipCamera

signal CustomOffset(offset : Vector2)

static var WritingText : bool = false

#-----------------------------------------------------------
func _ready() -> void:
	call_deferred("SetCamera")
	textInputParent.visible = false
	if (OS.get_name() == "Android"):
		$MarkerTextEditor/VBoxContainer.position.y = 120

#-----------------------------------------------------------
func _exit_tree() -> void:
	WritingText = false

#-----------------------------------------------------------
func SetCamera() -> void:
	var map = Map.GetInstance()
	if (!is_instance_valid(map)):
		return
	ship_camera = map.GetCamera()

#----------------------------------------------
func UpdateCameraZoom(_NewZoom : float) -> void:
	update()

#----------------------------------------------
func UpdateCameraPosition(_NewPos : Vector2) -> void:
	update()

#------------------------------------------------
func update() -> void:
	#global_position = get_parent().global_position - (get_viewport_rect().size/2)
	var psize = lineTarget.size / 2
	lineTarget.position = Vector2(XLine.position.x - psize.x, YLine.position.y - psize.y)
	if (Line != null):
		Line.StartingPos = Line.to_local(ship_camera.global_position)
		Line.UpdateLine((lineTarget.global_position + psize) - Line.position, ship_camera.zoom.x)
		Line.queue_redraw()

func IsDrawingText() -> bool:
	return textInputParent.visible

#-----------------------------------------------
##Text editor prompt
func _OnTextButtonPressed() -> void:
	WritingText = true
	textInput.grab_focus()
	textInputParent.visible = true

#-----------------------------------------------
func _on_text_confirm_pressed() -> void:
	WritingText = false
	textInputParent.visible = false
	var textblock = TextScene.instantiate() as MapMarkerText
	var pos = (lineTarget.position + (lineTarget.size / 2)) - (get_viewport_rect().size / 2)
	
	MapPointerManager.GetInstance().MapLonePos.add_child(textblock)
	textblock.add_to_group("ZoomAffected")
	textblock.UpdateCameraZoom(ship_camera.zoom.x)
	textblock.global_position = ship_camera.global_position + (pos / (ship_camera.zoom))
	textblock.SetText(textInput.text)
	textInput.text = ""
	PopUpManager.GetInstance().DoFadeNotif("Text marker placed")

#-----------------------------------------------------------
func IsDrawingLine() -> bool:
	return Line != null

#-----------------------------------------------------------
func _on_drone_button_pressed() -> void:
	if (Line == null):
		Line = LineScene.instantiate() as MapMarkerLine
		TempLineParent.add_child(Line)
		Line.global_position = lineTarget.global_position + (lineTarget.size / 2)
		Line.StartingPos = ship_camera.global_position
		Line.add_point(Vector2(0,0))
		Line.add_point(Vector2(0,0))
	else:
		var pos = Line.position - (get_viewport_rect().size / 2)
		TempLineParent.remove_child(Line)
		MapPointerManager.GetInstance().MapLonePos.add_child(Line)
		Line.add_to_group("ZoomAffected")
		Line.UpdateCameraZoom(ship_camera.zoom.x)
		Line.global_position = ship_camera.global_position + (pos / (ship_camera.zoom))
		Line.set_point_position(1, Line.get_point_position(1) / (ship_camera.zoom))
		#Line.get_child(0).position = (Line.get_point_position(1) / 2) - (Line.get_child(0).size / 2)
		Line = null
		PopUpManager.GetInstance().DoFadeNotif("Line marker placed")

#-----------------------------------------------------------
func UpdatePosCustom() -> void:
	var offset = YLine.global_position - get_local_mouse_position()
	CustomOffset.emit(offset)
	YLine.global_position = get_local_mouse_position()
	XLine.global_position = get_local_mouse_position()
	update()

#-----------------------------------------------------------
func _on_y_gas_range_changed(NewVal: float) -> void:
	YLine.global_position.y = clamp(YLine.global_position.y + NewVal * 5, 0, get_viewport_rect().size.y)
	update()

#-----------------------------------------------------------
func _on_x_gas_range_changed(NewVal: float) -> void:
	XLine.global_position.x = clamp(XLine.global_position.x + NewVal * 5, 0, get_viewport_rect().size.x)
	update()

#-----------------------------------------------------------
func LoadData(Dat : SD_MapMarkerEditor) -> void:
	for g in Dat.Lines:
		var newline = LineScene.instantiate() as MapMarkerLine
		MapPointerManager.GetInstance().MapLonePos.add_child(newline)
		newline.LoadData(g)
	for g in Dat.Texts:
		var newtext = TextScene.instantiate() as MapMarkerText
		MapPointerManager.GetInstance().MapLonePos.add_child(newtext)
		newtext.LoadData(g)

#-----------------------------------------------------------
func ToggleVisibilidy(t : bool) -> void:
	visible = t
	WritingText = textInputParent.visible

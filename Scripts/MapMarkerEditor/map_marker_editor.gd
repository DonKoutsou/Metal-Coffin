extends Control

class_name MapMarkerEditor

@export var LineScene : PackedScene
@export var TextScene : PackedScene


var Line : MapMarkerLine
var LineLeangth : float = 0

var ship_camera: Camera2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	call_deferred("SetCamera")
	$MarkerTextEditor.visible = false
	if (OS.get_name() == "Android"):
		$MarkerTextEditor/VBoxContainer.position.y = 120

func SetCamera() -> void:
	var map = Map.GetInstance()
	if (!is_instance_valid(map)):
		return
	ship_camera = map.GetCamera()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	#global_position = get_parent().global_position - (get_viewport_rect().size/2)
	var psize = $Panel.size / 2
	$Panel.position = Vector2($XLine.position.x - psize.x, $YLine.position.y - psize.y)
	if (Line != null):
		Line.UpdateLine(($Panel.global_position + psize) - Line.position, ship_camera.zoom.x)
		Line.queue_redraw()
func _OnTextButtonPressed() -> void:
	$MarkerTextEditor.visible = true

func _on_text_confirm_pressed() -> void:
	$MarkerTextEditor.visible = false
	var textblock = TextScene.instantiate() as MapMarkerText
	var pos = ($Panel.position + ($Panel.size / 2)) - (get_viewport_rect().size / 2)
	
	MapPointerManager.GetInstance().MapLonePos.add_child(textblock)
	textblock.add_to_group("LineMarkers")
	textblock.CamZoomUpdated(ship_camera.zoom.x)
	textblock.global_position = ship_camera.global_position + (pos / (ship_camera.zoom))
	textblock.SetText($MarkerTextEditor/VBoxContainer/TextEdit.text)
	$MarkerTextEditor/VBoxContainer/TextEdit.text = ""
	PopUpManager.GetInstance().DoFadeNotif("Text marker placed")
func _on_drone_button_pressed() -> void:
	if (Line == null):
		Line = LineScene.instantiate() as MapMarkerLine
		$Linetemp.add_child(Line)
		Line.global_position = $Panel.global_position + ($Panel.size / 2)
		Line.add_point(Vector2(0,0))
		Line.add_point(Vector2(0,0))
		LineLeangth = 0
	else:
		var pos = Line.position - (get_viewport_rect().size / 2)
		$Linetemp.remove_child(Line)
		MapPointerManager.GetInstance().MapLonePos.add_child(Line)
		Line.add_to_group("LineMarkers")
		Line.CamZoomUpdated(ship_camera.zoom.x)
		Line.global_position = ship_camera.global_position + (pos / (ship_camera.zoom))
		Line.set_point_position(1, Line.get_point_position(1) / (ship_camera.zoom))
		#Line.get_child(0).position = (Line.get_point_position(1) / 2) - (Line.get_child(0).size / 2)
		Line = null
		PopUpManager.GetInstance().DoFadeNotif("Line marker placed")

func _on_y_gas_range_changed(NewVal: float) -> void:
	$YLine.global_position.y = clamp($YLine.global_position.y + NewVal * 5, 0, get_viewport_rect().size.y)
	
func _on_x_gas_range_changed(NewVal: float) -> void:
	$XLine.global_position.x = clamp($XLine.global_position.x + NewVal * 5, 0, get_viewport_rect().size.x)

func LoadData(Dat : SD_MapMarkerEditor) -> void:
	for g in Dat.Lines:
		var newline = LineScene.instantiate() as MapMarkerLine
		MapPointerManager.GetInstance().MapLonePos.add_child(newline)
		newline.LoadData(g)
	for g in Dat.Texts:
		var newtext = TextScene.instantiate() as MapMarkerText
		MapPointerManager.GetInstance().MapLonePos.add_child(newtext)
		newtext.LoadData(g)

func ToggleVisibilidy(t : bool) -> void:
	visible = t

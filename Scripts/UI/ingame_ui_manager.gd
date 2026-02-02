extends CanvasLayer
class_name Ingame_UIManager

@export var _Inventory : InventoryManager
@export var _MapMarkerEditor : MapMarkerEditor
@export var PopupPlecement : Control
@export var EventHandler : UIEventHandler
@export var UnderstatUI : Control
@export var OverStatUI : Control

@export var Screen : Control
@export var ZoomUI : ZoomLvevel
@export var TUI : TeamUI

@export_group("Scenes")
@export_file("*.tscn") var PauseMenuSceneFile : String
@export_file("*.tscn") var DialogueSceneFile : String

var PauseContainer : PauseMenu

static var Instance :Ingame_UIManager
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Instance = self
	EventHandler.connect("PausePressed", Pause)
	EventHandler.connect("InventoryPressed", GetInventory().ToggleInventory)
	GetInventory().connect("InventoryToggled", EventHandler.OnScreenUIToggled)
	EventHandler.connect("DrawLinePressed", _MapMarkerEditor._on_drone_button_pressed)
	EventHandler.connect("DrawTextPressed", _MapMarkerEditor._OnTextButtonPressed)
	EventHandler.connect("MarkerEditorYRangeChanged", _MapMarkerEditor._on_y_gas_range_changed)
	EventHandler.connect("MarkerEditorXRangeChanged", _MapMarkerEditor._on_x_gas_range_changed)
	EventHandler.connect("MarkerEditorToggled", _MapMarkerEditor.ToggleVisibilidy)
	EventHandler.ZoomToggled.connect(ToggleZoomUI)
	EventHandler.TeamToggled.connect(ToggleTeamUI)
	_MapMarkerEditor.visible = false
	
	
	ToggleScreenGlitches(SettingsPanel.GetGlitch())

func ToggleZoomUI(t : bool) -> void:
	ZoomUI.Toggle(t)

func ToggleTeamUI(t : bool) -> void:
	TUI.Toggle(t)

func ToggleScreenGlitches(t : bool) -> void:
	var mat = Screen.material as ShaderMaterial
	var ImageFlicker = 0
	var Skip = 0
	if (t):
		ImageFlicker = 0.05
		Skip = 0.01
		
	mat.set_shader_parameter("image_flicker", ImageFlicker)
	mat.set_shader_parameter("skip", Skip)

static func GetInstance() -> Ingame_UIManager:
	return Instance

func AddUI(Scene : Node, UnderUI : bool = true, OverUI : bool = false) -> void:
	if (UnderUI):
		UnderstatUI.add_child(Scene)
	else: if (OverUI):
		OverStatUI.add_child(Scene)
	else:
		add_child(Scene)

func PlayDiag(Diags : Array[String], Avatar : Texture, TalkerName : String, StopInput : bool = false):
	var DiagplScene = ResourceLoader.load(DialogueSceneFile)
	var diag = DiagplScene.instantiate() as DialoguePlayer
	if (StopInput):
		diag.mouse_filter = Control.MOUSE_FILTER_STOP
	AddUI(diag, true)
	diag.PlayDialogue(Diags, Avatar, TalkerName)

func CallbackDiag (Diags : Array[String], Avatar : Texture, TalkerName : String, Callback : Callable, StopInput : bool = false):
	var DiagplScene = ResourceLoader.load(DialogueSceneFile)
	var diag = DiagplScene.instantiate() as DialoguePlayer
	if (StopInput):
		diag.mouse_filter = Control.MOUSE_FILTER_STOP
	AddUI(diag, true)
	diag.PlayDialogue(Diags, Avatar, TalkerName)
	diag.Callback = Callback

func ToggleInventoryButton(t : bool):
	$VBoxContainer/HBoxContainer/Panel/InventoryButton.disabled = !t

func GetInventory() -> InventoryManager:
	return _Inventory
#func GetCapUI() -> CaptainUI:
	#return _CaptainUI
func GetMapMarkerEditor() -> MapMarkerEditor:
	return _MapMarkerEditor

func Pause() -> void:
	var paused = get_tree().paused
	get_tree().paused = !paused
	if (paused):
		PauseContainer.queue_free()
	else:
		var PauseMenuScene = ResourceLoader.load(PauseMenuSceneFile)
		PauseContainer = PauseMenuScene.instantiate()
		add_child(PauseContainer)


func On_Game_Lost_Button_Pressed() -> void:
	World.GetInstance().EndGame()

#func Stuter() -> void:
	#var mat : ShaderMaterial = $Control3/Screen.material

func ToggleCrtEffect(T : bool) -> void:
	Screen.visible = T

func SetScreenRes(Res : Vector2) -> void:
	Screen.material.set_shader_parameter("res", Res)

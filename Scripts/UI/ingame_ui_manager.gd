extends CanvasLayer
class_name Ingame_UIManager

@export var _Inventory : InventoryManager
#@export var _CaptainUI : CaptainUI
@export var _MapMarkerEditor : MapMarkerEditor
@export var PauseContainer : Control
@export var DiagplScene : PackedScene
@export var Manual : FlightManual
@export var EventHandler : UIEventHandler
@export var UnderstatUI : Control
@export var OverStatUI : Control
@export var PopupPlecement : Control

signal GUI_Input(event)
static var Instance :Ingame_UIManager
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	PauseContainer.visible = false
	Instance = self
	EventHandler.connect("PausePressed", Pause)
	EventHandler.connect("InventoryPressed", GetInventory().ToggleInventory)
	
	GetInventory().connect("InventoryToggled", EventHandler.OnScreenUIToggled)
	EventHandler.connect("DrawLinePressed", _MapMarkerEditor._on_drone_button_pressed)
	EventHandler.connect("DrawTextPressed", _MapMarkerEditor._OnTextButtonPressed)
	EventHandler.connect("MarkerEditorYRangeChanged", _MapMarkerEditor._on_y_gas_range_changed)
	EventHandler.connect("MarkerEditorXRangeChanged", _MapMarkerEditor._on_x_gas_range_changed)
	EventHandler.connect("MarkerEditorToggled", _MapMarkerEditor.ToggleVisibilidy)
	_MapMarkerEditor.visible = false
	
	ToggleScreenGlitches(SettingsPanel.GetGlitch())

func ToggleScreenGlitches(t : bool) -> void:
	var mat = $Control3/Screen.material as ShaderMaterial
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
	var diag = DiagplScene.instantiate() as DialoguePlayer
	if (StopInput):
		diag.mouse_filter = Control.MOUSE_FILTER_STOP
	AddUI(diag, true)
	diag.PlayDialogue(Diags, Avatar, TalkerName)

func CallbackDiag (Diags : Array[String], Avatar : Texture, TalkerName : String, Callback : Callable, StopInput : bool = false):
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
	PauseContainer.visible = !paused
	#EventHandler.OnScreenUIToggled(paused)
	
func _on_save_pressed() -> void:
	if (CageFightWorld.GetInstance() != null):
		PopUpManager.GetInstance().DoFadeNotif("Can't save in a cagefight", PopupPlecement)
		return
	if (get_tree().get_nodes_in_group("CardFight").size() > 0):
		PopUpManager.GetInstance().DoFadeNotif("Can't save while in a fight", PopupPlecement)
		return
	SaveLoadManager.GetInstance().Save()
	PopUpManager.GetInstance().DoFadeNotif("Save successful", PopupPlecement)
func _on_exit_pressed() -> void:
	var world = World.GetInstance()
	if (world != null):
		world.EndGame()
		return
	var cardworld = CageFightWorld.GetInstance()
	if (cardworld != null):
		cardworld.EndGame()

func On_Game_Lost_Button_Pressed() -> void:
	World.GetInstance().EndGame()
	

		
		
func _on_control_3_gui_input(event: InputEvent) -> void:
	GUI_Input.emit(event)

#func Stuter() -> void:
	#var mat : ShaderMaterial = $Control3/Screen.material

func ToggleCrtEffect(T : bool) -> void:
	$Control3/Screen.visible = T

func SetScreenRes(Res : Vector2) -> void:
	$Control3/Screen.material.set_shader_parameter("res", Res)

func _on_flight_manual_pressed() -> void:
	Manual.visible = true

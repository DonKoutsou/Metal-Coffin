extends CanvasLayer
class_name Ingame_UIManager

@export var _Inventory : InventoryManager
#@export var _CaptainUI : CaptainUI
@export var _MapMarkerEditor : MapMarkerEditor
@export var PauseContainer : Control
@export var DiagplScene : PackedScene

static var Instance :Ingame_UIManager
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Instance = self
	
static func GetInstance() -> Ingame_UIManager:
	return Instance

func AddUI(Scene : Node, UnderUI : bool = true, OverUI : bool = false) -> void:
	if (UnderUI):
		$Control3/UnderStatUI.add_child(Scene)
	else: if (OverUI):
		add_child(Scene)
	else:
		add_child(Scene)

func PlayDiag(Diags : Array[String], StopInput : bool = false):
	var diag = DiagplScene.instantiate() as DialoguePlayer
	if (StopInput):
		diag.MouseFilter = StopInput
	AddUI(diag, true)
	diag.PlayDialogue(Diags)

func CallbackDiag (Diags : Array[String], Callback : Callable, StopInput : bool = false):
	var diag = DiagplScene.instantiate() as DialoguePlayer
	if (StopInput):
		diag.mouse_filter = Control.MOUSE_FILTER_STOP
	AddUI(diag, true)
	diag.PlayDialogue(Diags)
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
func _on_save_pressed() -> void:
	SaveLoadManager.GetInstance().Save()
	PopUpManager.GetInstance().DoFadeNotif("Save successful")
func _on_exit_pressed() -> void:
	World.GetInstance().WRLD_OnGameEnded.emit()
func On_Game_Lost_Button_Pressed() -> void:
	World.GetInstance().WRLD_OnGameEnded.emit()
func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("Pause")):
		Pause()

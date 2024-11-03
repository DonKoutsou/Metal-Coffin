extends CanvasLayer
class_name Ingame_UIManager

@export var DiagplScene : PackedScene

static var Instance :Ingame_UIManager
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Instance = self
	
static func GetInstance() -> Ingame_UIManager:
	return Instance

func AddUI(Scene : Node, UnderUI : bool = true, OverUI : bool = false) -> void:
	if (UnderUI):
		$UnderStatUI.add_child(Scene)
	else: if (OverUI):
		$OverStatUI.add_child(Scene)
	else:
		$VBoxContainer.add_child(Scene)

func PlayDiag(Diags : Array[String], StopInput : bool = false):
	var diag = DiagplScene.instantiate() as DialoguePlayer
	if (StopInput):
		diag.MouseFilter = StopInput
	AddUI(diag, false, true)
	diag.PlayDialogue(Diags)

func CallbackDiag (Diags : Array[String], Callback : Callable, StopInput : bool = false):
	var diag = DiagplScene.instantiate() as DialoguePlayer
	if (StopInput):
		diag.mouse_filter = Control.MOUSE_FILTER_STOP
	AddUI(diag, false, true)
	diag.PlayDialogue(Diags)
	diag.Callback = Callback

func ToggleInventoryButton(t : bool):
	
	$VBoxContainer/HBoxContainer/InventoryButton.disabled = !t

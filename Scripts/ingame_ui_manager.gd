extends CanvasLayer
class_name Ingame_UIManager

@export var DiagplScene : PackedScene

static var Instance :Ingame_UIManager
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Instance = self
static func GetInstance() -> Ingame_UIManager:
	return Instance

func AddUI(Scene : Node, UnderUI : bool = true) -> void:
	if (UnderUI):
		$UnderStatUI.add_child(Scene)
	else:
		$VBoxContainer.add_child(Scene)

func PlayDiag(Diags : Array[String]):
	var diag = DiagplScene.instantiate() as DialoguePlayer
	AddUI(diag)
	diag.PlayDialogue(Diags)

func CallbackDiag (Diags : Array[String], Callback : Callable):
	var diag = DiagplScene.instantiate() as DialoguePlayer
	AddUI(diag)
	diag.PlayDialogue(Diags)
	diag.Callback = Callback

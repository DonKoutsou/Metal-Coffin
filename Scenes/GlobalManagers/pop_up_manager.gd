extends Node

class_name PopUpManager
@export var CustomPop : PackedScene
@export var CustomConfirm : PackedScene
@export var FadNot : PackedScene
static var Instance : PopUpManager
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Instance = self
	pass # Replace with function body.

static func GetInstance() -> PopUpManager:
	return Instance
	
func DoPopUp(Text : String, Parent : Node):
	var dig = CustomPop.instantiate() as AcceptDialog
	Parent.add_child(dig)
	dig.dialog_text = Text
	dig.popup_centered()
	
func DoConfirm(Title : String, Text : String, ConfirmText : String, Method : Callable, Parent : Node):
	var dig = CustomConfirm.instantiate() as ConfirmationDialog
	dig.connect("confirmed", Method)
	dig.title = Title
	#add_child(dig)
	#dig.title = 
	dig.dialog_text = Text
	dig.ok_button_text = ConfirmText
	dig.popup_exclusive_centered(Parent)

var CurrentlyShownFade : Array[String]

func DoFadeNotif(Text : String, Parent : Node = null, overridetime : float = 4):
	if (CurrentlyShownFade.has(Text)):
		return
	
	CurrentlyShownFade.append(Text)
	
	var f = get_tree().get_nodes_in_group("FadeNotif")
	for g in f:
		g.Finished.emit()
		g.queue_free()
	
	var UpdatedText = Text
	if (Text.find("\n") == 0):
		for g in Text.length():
			if (g > 25 and Text.substr(g, 1) == " "):
				UpdatedText = Text.insert(g, "\n")
				break
	
	var dig = FadNot.instantiate() as FadeNotif
	dig.alph = overridetime
	dig.Finished.connect(FadeFinished.bind(Text))
	dig.SetText(UpdatedText)
	if (is_instance_valid(Parent)):
		Parent.add_child(dig)
	else:
		Ingame_UIManager.GetInstance().PopupPlecement.add_child(dig)
	
func FadeFinished(Text : String) -> void:
	CurrentlyShownFade.erase(Text)
	
	

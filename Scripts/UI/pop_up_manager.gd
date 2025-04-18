extends Control

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
	
func DoPopUp(Text : String):
	var dig = CustomPop.instantiate() as AcceptDialog
	add_child(dig)
	dig.dialog_text = Text
	dig.popup_centered()
	
func DoConfirm(Title : String, Text : String, ConfirmText : String, Method : Callable):
	var dig = CustomConfirm.instantiate() as ConfirmationDialog
	dig.connect("confirmed", Method)
	#add_child(dig)
	#dig.title = 
	dig.dialog_text = Text
	dig.ok_button_text = ConfirmText
	dig.popup_exclusive_centered(self)
	
func DoFadeNotif(Text : String, overridetime : float = 4):
	var f = get_tree().get_nodes_in_group("FadeNotif")
	if (f.size() > 0):
		f[0].queue_free()
	var dig = FadNot.instantiate() as FadeNotif
	dig.alph = overridetime
	add_child(dig)
	dig.SetText(Text)

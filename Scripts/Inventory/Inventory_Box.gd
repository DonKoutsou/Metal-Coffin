@tool
extends Control
class_name Inventory_Box

@export var Butto : Button

var box : Inventory_Box_Res

signal ItemSelected(Box : Inventory_Box_Res)


func Initialise(boxRes : Inventory_Box_Res):
	box = boxRes
	box.AmmChanged.connect(UpdateAmm)
	box.ItemChanged.connect(_UpdateItemIcon)
	
	if (box._ContentAmmout > 0):
		_UpdateItemIcon(box._ContainedItem)
		UpdateAmm(box._ContentAmmout)

func _ready() -> void:
	if (Engine.is_editor_hint()):
		return
	UISoundMan.GetInstance().AddSelf(Butto)

func _exit_tree() -> void:
	UISoundMan.GetInstance().RemoveSelf(Butto)

func UpdateAmm(newAmm : int) -> void:
	if (newAmm <= 0):
		Butto.disabled = true
		Butto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		Butto.mouse_filter = Control.MOUSE_FILTER_PASS
	_UpdateAmmountLabel(newAmm)

func UpdateAmmNoDissable(newAmm : int) -> void:
	_UpdateAmmountLabel(newAmm)

func _UpdateAmmountLabel(newAmm : int) -> void:
	var Text = $ItemButton/PanelContainer/Label
	Text.text = var_to_str(newAmm)
	$ItemButton/PanelContainer.visible = newAmm > 1

func Enable() -> void:
	Butto.disabled = false
	Butto.mouse_filter = Control.MOUSE_FILTER_PASS
	
func _UpdateItemIcon(it : Item) -> void:
	if (it):
		$ItemButton.text = it.GetItemName()
		Butto.disabled = false
	else:
		$ItemButton.text = ""

func _On_Item_Pressed() -> void:
	ItemSelected.emit(box)

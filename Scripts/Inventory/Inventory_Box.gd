@tool
extends Control
class_name Inventory_Box

@export var Butto : Button
@export var txt : Label
@export var AmmountLabel : Label

var box : Inventory_Box_Res
var allowDissable : bool = true

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
	if (!allowDissable):
		Enable()

func _exit_tree() -> void:
	UISoundMan.GetInstance().RemoveSelf(Butto)

func UpdateAmm(newAmm : int) -> void:
	if (allowDissable):
		if (newAmm <= 0):
			$ItemButton/HBoxContainer.hide()
			Butto.disabled = true
			Butto.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			Butto.mouse_filter = Control.MOUSE_FILTER_PASS
			$ItemButton/HBoxContainer.show()
	_UpdateAmmountLabel(newAmm)

func UpdateAmmNoDissable(newAmm : int) -> void:
	_UpdateAmmountLabel(newAmm)

func _UpdateAmmountLabel(newAmm : int) -> void:
	AmmountLabel.text = var_to_str(newAmm)
	$ItemButton/HBoxContainer/PanelContainer.visible = newAmm > 1

func Enable() -> void:
	Butto.disabled = false
	Butto.mouse_filter = Control.MOUSE_FILTER_PASS
	
func _UpdateItemIcon(it : Item) -> void:
	if (it):
		txt.text = it.GetItemName()
		Butto.disabled = false
	else:
		txt.text = ""

func _On_Item_Pressed() -> void:
	ItemSelected.emit(box)

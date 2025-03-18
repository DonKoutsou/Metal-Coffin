@tool
extends Control
class_name Inventory_Box

@export var Butto : Button

var _ParentInventory : CharacterInventory
var _ContainedItem : Item
var _ContentAmmout : int

signal ItemSelected(Box : Inventory_Box)

func Initialise(Parent : CharacterInventory):
	_ParentInventory = Parent


func GetParentInventory() -> CharacterInventory:
	return _ParentInventory


func RegisterItem(It : Item) -> void:
	_ContainedItem = It
	_UpdateItemIcon()
	Butto.disabled = false


func UpdateAmm(Amm : int) -> void:
	_ContentAmmout = max(_ContentAmmout + Amm, 0)
	if (_ContentAmmout <= 0):
		_ContainedItem = null
		Butto.disabled = true
		_UpdateItemIcon()
		Butto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		Butto.mouse_filter = Control.MOUSE_FILTER_PASS
	_UpdateAmmountLabel()

func GetContainedItem() -> Item:
	return _ContainedItem


func GetContainedItemName() -> String:
	return _ContainedItem.ItemName

func IsEmpty() -> bool:
	return _ContentAmmout == 0

func HasSpace() -> bool:
	return _ContentAmmout < _ContainedItem.MaxStackCount

func _UpdateAmmountLabel() -> void:
	var Text = $PanelContainer/Label
	Text.text = var_to_str(_ContentAmmout)
	$PanelContainer.visible = _ContentAmmout > 1

func _UpdateItemIcon() -> void:
	if (_ContainedItem):
		$ItemButton.text = _ContainedItem.ItemName
		#$ItemButton/ItemName.text = _ContainedItem.ItemName
		#$ItemButton/TextureRect.texture = _ContainedItem.ItemIconSmol
		#if (_ContainedItem is UsableItem):
			#$TextureRect/TextureRect.modulate = _ContainedItem.ItecColor
		#else:
			#$TextureRect/TextureRect.modulate = Color.WHITE
	else:
		$ItemButton/ItemName.text = ""

func _On_Item_Pressed() -> void:
	if (_ContentAmmout == 0):
		return
	ItemSelected.emit(self)

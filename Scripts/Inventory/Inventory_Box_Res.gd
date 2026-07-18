@tool
extends RefCounted
class_name Inventory_Box_Res

var _ParentInventory : CharacterInventory
var _ContainedItem : Item
var _ContentAmmout : int

signal AmmChanged(NewAmm : int)
signal ItemChanged(NewIt : Item)

#--------------------------------------------------
func Initialise(Parent : CharacterInventory):
	_ParentInventory = Parent

#--------------------------------------------------
func GetParentInventory() -> CharacterInventory:
	return _ParentInventory

#--------------------------------------------------
func RegisterItem(It : Item) -> void:
	_ContainedItem = It
	ItemChanged.emit(It)

#--------------------------------------------------
func UpdateAmm(Amm : int) -> void:
	_ContentAmmout = max(_ContentAmmout + Amm, 0)
	AmmChanged.emit(_ContentAmmout)
	if (_ContentAmmout <= 0):
		_ContainedItem = null
		ItemChanged.emit(null)

#--------------------------------------------------
func GetContainedItem() -> Item:
	return _ContainedItem

#--------------------------------------------------
func GetContainedItemName() -> String:
	return _ContainedItem.GetItemName()

#--------------------------------------------------
func IsEmpty() -> bool:
	return _ContentAmmout == 0

#--------------------------------------------------
func HasSpace() -> bool:
	return _ContentAmmout < _ContainedItem.MaxStackCount

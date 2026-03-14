@tool
extends Item
class_name PlaceHolderItem

@export var ContainedItem : Item

func GetItemName() -> String:
	return "Reserved Spot For {0}".format([ContainedItem.GetItemName()])

func GetItemDesc() -> String:
	return "Installing Part"

func IsSame(It : Item) -> bool:
	return ContainedItem.GetItemName() == It.GetItemName()

func GetMerchItemDesc(Ships : Array[MapShip]) -> String:
	return ContainedItem.GetMerchItemDesc(Ships)

func GetWorkshopItemDesc() -> String:
	return ContainedItem.GetWorkshopItemDesc()

extends PanelContainer

class_name WorkShopItem

@export var ItemName : Label
@export var ShopOwnedT : Label
@export var ItPriceT : Label

signal OnItemBought(It : Item)

var ItPrice : float = 10
var It : Item
var ShopAmm : int = 10

func _ready() -> void:
	ItemName.text = It.ItemName
	ItPriceT.text = var_to_str(ItPrice).replace(".0", "")
	ShopOwnedT.text = var_to_str(ShopAmm)

func Init(ShopItem : Item, Price : float, ShopAmmount : int) -> void:
	It = ShopItem
	ItPrice = Price
	ShopAmm = ShopAmmount

var Accum : float = 0
func InstallButtonPressed() -> void:
	OnItemBought.emit(It)

func ToggleDetails(t : bool) -> void:
	$VBoxContainer/HBoxContainer.visible = t
	$VBoxContainer/ProgressBar.visible = t

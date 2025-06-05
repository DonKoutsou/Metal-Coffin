extends PanelContainer

class_name WorkShopItem

@export var ItemName : Label
@export var ShopOwnedT : Label
@export var ItPriceT : Label

signal OnItemBought()

var ItPrice : float = 10
var It : Item
var ShopAmm : int = 10

func _ready() -> void:
	ItemName.text = It.ItemName
	ItPriceT.text = var_to_str(ItPrice).replace(".0", "")
	ShopOwnedT.text = var_to_str(ShopAmm)

func Init(M : Merchandise) -> void:
	It = M.It
	ItPrice = M.It.Cost
	ShopAmm = M.Amm

var Accum : float = 0
func InstallButtonPressed() -> void:
	OnItemBought.emit()

func ToggleDetails(t : bool) -> void:
	$VBoxContainer/HBoxContainer.visible = t
	$VBoxContainer/ProgressBar.visible = t

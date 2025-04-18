extends PanelContainer

class_name TownShopItem

@export var ItemName : Label
@export var Bar : ProgressBar
@export var PlOwnedT : Label
@export var ShopOwnedT : Label
@export var ItPriceT : Label
@export var PlWallet : Wallet

signal OnItemBought(It : Item)
signal OnItemSold(It : Item)

#var PlFunds : int = 10000
var LandedShip : MapShip
var ItPrice : float = 10
var It : Item
var ShopAmm : int = 10
var PlAmm : int = 4
var BoughtAmm : int = 0

func _ready() -> void:
	ItemName.text = It.ItemName
	ItPriceT.text = var_to_str(ItPrice)
	ShopOwnedT.text = var_to_str(ShopAmm)
	PlOwnedT.text = var_to_str(PlAmm)
	Bar.max_value = ShopAmm + PlAmm
	Bar.value = PlAmm

var Accum : float = 0
func ItemBar_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		var rel = event.relative
		if (rel.x > 0 and Bar.max_value == Bar.value):
			return
		else : if (rel.x < 0 and Bar.value == 0):
			return
		Accum += rel.x / 2
		if (abs(Accum) < 10):
			return
		UpdateBar(sign(Accum))
		Accum = 0
	else : if (event is InputEventScreenDrag):
		var rel = event.relative
		if (rel > 0 and Bar.max_value == Bar.value):
			return
		else : if (rel < 0 and Bar.value == 0):
			return
		Accum += rel.x / 2
		if (abs(Accum) < 10):
			return
		UpdateBar(sign(Accum))
		Accum = 0

func UpdateBar(Added : int):
	$AudioStreamPlayer.play()
	if (Added > 0):
		if (!InventoryManager.GetInstance().FleetHasSpace(It, LandedShip)):
			PopUpManager.GetInstance().DoFadeNotif("No Space available to buy armament.")
			return
		OnItemBought.emit(It)
	else :
		OnItemSold.emit(It)
		
	if (Added * ItPrice > PlWallet.Funds):
		Added = PlWallet.Funds / ItPrice
	if (Added > ShopAmm):
		Added = ShopAmm
	var NowPlAmm = PlAmm + BoughtAmm + Added
	if (NowPlAmm < 0):
		Added = 0 - (PlAmm + BoughtAmm)
		NowPlAmm = 0
	#if (NowPlAmm > PlMaxFuel):
		#Added = PlMaxFuel - (PlFuel + BoughtAmm)
		#NewPlFuel = Added
	ShopAmm -= Added
	BoughtAmm += Added
	PlWallet.AddFunds( -(Added * ItPrice) )
	Bar.value = PlAmm + BoughtAmm
	#FundAmm.text = var_to_str(roundi(PlFunds)) + " ₯"
	PlOwnedT.text = var_to_str(roundi(PlAmm + BoughtAmm))
	ShopOwnedT.text = var_to_str(roundi(ShopAmm))

func ToggleDetails(t : bool) -> void:
	$VBoxContainer/HBoxContainer.visible = t
	$VBoxContainer/ProgressBar.visible = t

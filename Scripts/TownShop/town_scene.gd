extends Control

class_name TownScene
@export_group("Merchandise")
@export var Merch : Array[Merchandise]
@export_group("Nodes")
#@export var FundAmm : Label
@export var PortName : Label
@export var PortBuffText : RichTextLabel

@export var TownBG : TownBackground

@export_group("Buttons")
@export var MerchendiseButton : Button
@export var WorkshopButton : Button
@export var FuelButton : Button

@export_group("Scenes")

@export var MerchShopScene : PackedScene
@export var FuelStorageScene : PackedScene
@export var WorkshopScene : PackedScene
#"[color=#ffc315

var TownFuel : float = 0
var BoughtFuel : float = 0
var BoughtRepairs : float = 0

var TownSpot : MapSpot

signal TransactionFinished(BFuel : float, BRepair : float, Ship : MapShip, TradeScene : TownScene)

var LandedShips : Array[MapShip]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PortName.text = TownSpot.GetSpotName() + " City Port"
	SetTownBuffs()
	
	for g in TownSpot.Merch:
		var It = g.It
		for z in Merch:
			if (It == z.It):
				z.Amm = g.Amm
	#signal OnItemBought(It : Item)

	UISoundMan.GetInstance().Refresh()

func SetTownBuffs() -> void:
	var Text : String = ""
	if (TownSpot.HasFuel()):
		Text += "[p][img]res://Assets/Items/Fuel.png[/img] REFUEL TIME/COST -[p]"
	if (TownSpot.HasRepair()):
		Text += "[img]res://Assets/Items/cubeforce.png[/img] REPAIR TIME/COST -[p]"
	if (TownSpot.HasUpgrade()):
		Text += "[img]res://Assets/Items/materials-science.png[/img] UPGRADE TIME/COST -[p][p]"
	PortBuffText.text = Text

func On_MunitionShop_pressed() -> void:
	MerchShop.visible = true
	WorkshopButton.set_pressed_no_signal(false)



func On_RefRef_Pressed() -> void:
	MerchShop.visible = false
	MerchendiseButton.set_pressed_no_signal(false)

func OnRefuelShopPressed() -> void:
	var Scene = FuelStorageScene.instantiate() as TownFuelStorages
	add_child(Scene)
	
	var FuelPricePerTon : float
	if (!TownSpot.HasFuel()):
		FuelPricePerTon = 100
	else:
		FuelPricePerTon = 50
	var RepairpricePerRepairValue : float
	if (!TownSpot.HasRepair()):
		RepairpricePerRepairValue = 200
	else:
		RepairpricePerRepairValue = 100
	
	Scene.Init(TownFuel, BoughtFuel, FuelPricePerTon, BoughtRepairs, RepairpricePerRepairValue, LandedShips)
	Scene.FuelTransactionFinished.connect(FuelExchangeFinished)

func FuelExchangeFinished(RemainingReserves : float, Fuel : float, Repair : float) -> void:
	TownFuel = RemainingReserves
	BoughtFuel = Fuel
	BoughtRepairs = Repair
	

func OnUpgradeShopPressed() -> void:
	var WShop = WorkshopScene.instantiate() as WorkShop
	add_child(WShop)
	WShop.Init(LandedShips)

func OnMunitionShopToggled() -> void:
	var Scene = MerchShopScene.instantiate() as MerchShop
	add_child(Scene)
	Scene.ItemSold.connect(OnItemSold)
	Scene.ItemBought.connect(OnItemBought)
	Scene.Init(LandedShips, Merch)

func OnItemSold(It : Item) -> void:
	for g in LandedShips:
		var inv = g.Cpt.GetCharacterInventory()
		if (inv.HasItem(It)):
			inv.RemoveItem(It)

	for g in TownSpot.Merch:
		if (g.It == It):
			g.Amm += 1
			break

func OnItemBought(It : Item) -> void:
	for g in LandedShips:
		var inv = g.Cpt.GetCharacterInventory()
		if (inv.HasSpaceForItem(It)):
			inv.AddItem(It)

	for g in TownSpot.Merch:
		if (g.It == It):
			g.Amm -= 1
			break

func _on_town_background_position_changed() -> void:
	WorkshopButton.global_position = TownBG.GetLocationForPosition(TownBackground.Location.WORKSHOP)
	MerchendiseButton.global_position = TownBG.GetLocationForPosition(TownBackground.Location.MERCH)
	FuelButton.global_position = TownBG.GetLocationForPosition(TownBackground.Location.FUEL)

func _on_button_pressed() -> void:
	TransactionFinished.emit(BoughtFuel, BoughtRepairs, LandedShips, self)

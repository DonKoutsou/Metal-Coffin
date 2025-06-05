extends Control

class_name TownScene
@export_group("Merchandise")
@export var Merch : Array[Merchandise]
@export var WorkShopMerch : Array[Merchandise]
@export_group("Nodes")
#@export var FundAmm : Label
@export var PortName : Label
@export var PortBuffText : RichTextLabel
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
var TownBG : TownBackground
signal TransactionFinished(BFuel : float, BRepair : float, Ship : MapShip, TradeScene : TownScene)

var LandedShips : Array[MapShip]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	TownBG = TownSpot.SpotType.BackgroundScene.instantiate() as TownBackground
	$SubViewportContainer/SubViewport.add_child(TownBG)
	TownBG.PositionChanged.connect(_on_town_background_position_changed)
	PortName.text = TownSpot.GetSpotName() + " City Port"
	SetTownBuffs()
	
	for g in TownSpot.Merch:
		var It = g.It
		for z in Merch:
			if (It.IsSame(z.It)):
				z.Amm = g.Amm
	for g in TownSpot.WorkShopMerch:
		var It = g.It
		for z in WorkShopMerch:
			if (It.IsSame(z.It)):
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
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.FUEL_SHOP)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.FUEL_SHOP)
		ActionTracker.GetInstance().ShowTutorial("Shipyard", "Here in the Shipyard, you can repair and refuel your ships! You can see the full ammount of fuel/hull condition of you landed ships.\nEnsure your fleet is fully refueled and all necessary repairs are completed before embarking on your next mission!", [], true)
	

func FuelExchangeFinished(RemainingReserves : float, Fuel : float, Repair : float) -> void:
	TownFuel = RemainingReserves
	BoughtFuel = Fuel
	BoughtRepairs = Repair
	

func OnUpgradeShopPressed() -> void:
	var WShop = WorkshopScene.instantiate() as WorkShop
	add_child(WShop)
	WShop.Init(LandedShips, TownSpot.HasUpgrade(), WorkShopMerch)
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.UPGRADE_SHOP)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.UPGRADE_SHOP)
		ActionTracker.GetInstance().ShowTutorial("Workshop", "In the workshop you can inspect your fleets and choose parts to upgrade. Upgraded parts provide better stats for the ship and also extra [color=#ffc315]cards[/color] for the ship's [color=#ffc315]deck[/color].\n\nEach ship can have one of their parts being upgraded at each time. Upgrade progress updates only while the simulation is running.", [], true)

func OnMunitionShopToggled() -> void:
	var Scene = MerchShopScene.instantiate() as MerchShop
	add_child(Scene)
	Scene.ItemSold.connect(OnItemSold)
	Scene.ItemBought.connect(OnItemBought)
	Scene.Init(LandedShips, Merch)
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.MERCH_SHOP)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.MERCH_SHOP)
		ActionTracker.GetInstance().ShowTutorial("Munition Shop", "In the munition shop you can supply your ships with various single use items, from [color=#ffc315]Missiles[/color] to [color=#ffc315]Fire Suppression Units[/color]. Some of those items are ment to be used in the overworld while others will provide you with extra [color=#ffc315]cards[/color] in your [color=#ffc315]deck[/color].", [], true)
	

func OnItemSold(It : Item) -> void:
	PopupManager.GetInstance().DoFadeNotif("{0} has been sold".format([It.ItemName]))
	for g in LandedShips:
		var inv = g.Cpt.GetCharacterInventory()
		if (inv.HasItem(It)):
			inv.RemoveItem(It)
			break
	for g in TownSpot.Merch:
		if (g.It == It):
			g.Amm += 1
			break

func OnItemBought(It : Item) -> void:
	PopupManager.GetInstance().DoFadeNotif("{0} bought".format([It.ItemName]))
	for g in LandedShips:
		var inv = g.Cpt.GetCharacterInventory()
		if (inv.HasSpaceForItem(It)):
			inv.AddItem(It)
			break

	for g in TownSpot.Merch:
		if (g.It == It):
			g.Amm -= 1
			break

func _on_town_background_position_changed() -> void:
	var WorkshopNode = TownBG.GetNodeForPosition(TownBackground.Location.WORKSHOP)
	WorkshopButton.global_position = WorkshopNode.global_position
	(WorkshopButton.get_child(0) as Line2D).set_point_position(1, (WorkshopButton.get_child(0) as Line2D).to_local(WorkshopNode.get_child(0).global_position))
	var MerchendiseNode = TownBG.GetNodeForPosition(TownBackground.Location.MERCH)
	MerchendiseButton.global_position = MerchendiseNode.global_position
	(MerchendiseButton.get_child(0) as Line2D).set_point_position(1, (MerchendiseButton.get_child(0) as Line2D).to_local(MerchendiseNode.get_child(0).global_position))
	var FuelNode = TownBG.GetNodeForPosition(TownBackground.Location.FUEL)
	FuelButton.global_position = FuelNode.global_position
	(FuelButton.get_child(0) as Line2D).set_point_position(1, (FuelButton.get_child(0) as Line2D).to_local(FuelNode.get_child(0).global_position))

func _on_button_pressed() -> void:
	TransactionFinished.emit(BoughtFuel, BoughtRepairs, LandedShips, self)

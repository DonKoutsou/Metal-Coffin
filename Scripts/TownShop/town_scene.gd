extends Control

class_name TownScene

@export_group("Nodes")
#@export var FundAmm : Label
@export var PortName : Label
@export var Population : Label
@export var PortBuffText : RichTextLabel
@export_group("Buttons")
@export var MerchendiseButton : Button
@export var WorkshopButton : Button
@export var FuelButton : Button
@export var RepairButton : Button

@export_group("Scenes")
@export var MerchShopScene : PackedScene
@export var FuelStorageScene : PackedScene
@export var RepairStationScene : PackedScene
@export var WorkshopScene : PackedScene

var BoughtFuel : float = 0

var TownSpot : MapSpot
var TownBG : TownBackground
signal TransactionFinished(BFuel : float,  Ship : MapShip, TradeScene : TownScene)

var LandedShips : Array[MapShip]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Setting up background, different for village/city/capital
	TownBG = TownSpot.SpotType.BackgroundScene.instantiate() as TownBackground
	$SubViewportContainer/SubViewport.add_child(TownBG)
	TownBG.PositionChanged.connect(_on_town_background_position_changed)
	#Set the port's name on the UI along with the town's buffs
	PortName.text = TownSpot.GetSpotName() + " City Port"
	Population.text = "Population : {0}".format([snapped(TownSpot.Population, 1000)])
	SetTownBuffs()
	
	UISoundMan.GetInstance().Refresh()

func SetTownBuffs() -> void:
	var Text : String = ""
	if (TownSpot.HasFuel()):
		Text += "[p][img={32}x{32}]res://Assets/Items/Fuel.png[/img] REFUEL TIME/COST -[p]"
	if (TownSpot.HasRepair()):
		Text += "[img={32}x{32}]res://Assets/Items/cubeforce.png[/img] REPAIR TIME/COST -[p]"
	if (TownSpot.HasUpgrade()):
		Text += "[img={32}x{32}]res://Assets/Items/Wrench.png[/img] UPGRADE TIME/COST -[p][p]"
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
	
	Scene.Init(BoughtFuel, FuelPricePerTon, LandedShips, TownSpot)
	Scene.FuelTransactionFinished.connect(FuelExchangeFinished)
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.FUEL_SHOP)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.FUEL_SHOP)
		ActionTracker.GetInstance().ShowTutorial("Fuel Storage", "In the Fuel Storage you can buy fuel for your fleet.\nYou can see the full ammount of [color=#ffc315]FUEL[/color] of you landed ships.\nEnsure your fleet is fully refueled before embarking on your next mission!", [], true)

func OnRepairStationPressed() -> void:
	var Scene = RepairStationScene.instantiate() as RepairStation
	add_child(Scene)

	Scene.Init(TownSpot.HasRepair(), LandedShips)
	#Scene.FuelTransactionFinished.connect(FuelExchangeFinished)
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.REPAIR_SHOP)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.REPAIR_SHOP)
		ActionTracker.GetInstance().ShowTutorial("Repair Bay", "In the Repair Bay you can buy repair parts for your fleet.\nYou can see the hull condition of each of your ships and also their repair price. Buying all the nececary repair parts will allow the ship to slowly repair itself.\nAfter buying the parts the fleet can depart and keep repairing on another port, bought ship parts stay with the ship.", [], true)


func FuelExchangeFinished(Fuel : float) -> void:
	BoughtFuel = Fuel
	

func OnUpgradeShopPressed() -> void:
	var WShop = WorkshopScene.instantiate() as WorkShop
	add_child(WShop)
	WShop.Init(LandedShips, TownSpot.HasUpgrade(), TownSpot.WorkShopMerch)
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.UPGRADE_SHOP)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.UPGRADE_SHOP)
		ActionTracker.GetInstance().ShowTutorial("Workshop", "In the workshop you can inspect your fleet and choose parts to [color=#ffc315]Upgrade[/color] or [color=#ffc315]Install[/color].\nUpgraded parts provide better stats and also extra [color=#ffc315]Cards[/color] for the ship's [color=#ffc315]deck[/color].\nEach ship can have only one of their parts being upgraded at each time.\n[color=#ffc315]Upgrade[/color] progress updates only while the simulation is running.", [], true)

func OnMunitionShopToggled() -> void:
	var Scene = MerchShopScene.instantiate() as MerchShop
	add_child(Scene)
	Scene.ItemSold.connect(OnItemSold)
	Scene.ItemBought.connect(OnItemBought)
	Scene.Init(LandedShips, TownSpot.Merch)
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.MERCH_SHOP)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.MERCH_SHOP)
		ActionTracker.GetInstance().ShowTutorial("Munition Shop", "In the munition shop you can supply your ships with various single use items, from [color=#ffc315]Missiles[/color] to [color=#ffc315]Fire Suppression Units[/color].\nSome of those [color=#ffc315]Items[/color] are ment to be used in the overworld while others will provide you with extra [color=#ffc315]Cards[/color] for your [color=#ffc315]Deck[/color].", [], true)
	

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
			return
	var Merch = Merchandise.new()
	Merch.It = It
	Merch.Amm = 1
	TownSpot.Merch.append(Merch)
	
func OnItemBought(It : Item) -> void:
	PopupManager.GetInstance().DoFadeNotif("{0} bought".format([It.ItemName]))
	
	var Added = false
	
	for g in LandedShips:
		var inv = g.Cpt.GetCharacterInventory()
		if (!inv.HasSpaceForItem(It)):
			continue
		if (It is AmmoItem and inv.HasWeapon(It.WType)):
			inv.AddItem(It)
			Added = true
			break
		else : if (It is MissileItem and inv.HasWeapon(CardStats.WeaponType.ML)):
			inv.AddItem(It)
			Added = true
			break
	if (!Added):
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

	var RepairNode = TownBG.GetNodeForPosition(TownBackground.Location.REPAIR)
	RepairButton.global_position = RepairNode.global_position
	(RepairButton.get_child(0) as Line2D).set_point_position(1, (RepairButton.get_child(0) as Line2D).to_local(RepairNode.get_child(0).global_position))

func _on_button_pressed() -> void:
	TransactionFinished.emit(BoughtFuel, LandedShips, self)

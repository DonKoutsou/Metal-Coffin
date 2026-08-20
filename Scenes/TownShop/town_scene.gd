extends Control

class_name TownScene

@export_group("Nodes")
#@export var FundAmm : Label
@export var PortName : Label
@export var Population : Label
@export var PortBuffText : RichTextLabel
@export var PlWallet : Wallet
@export_group("Buttons")
@export var MerchendiseButton : Button
@export var MerchendiseButton2 : Button

@export var WorkshopButton : Button
@export var WorkshopButton2 : Button

@export var FuelButton : Button
@export var FuelButton2 : Button

@export var RepairButton : Button
@export var RepairButton2 : Button

@export var RecruitButton : Button
@export var RecruitButton2 : Button

@export_group("Scenes")
@export var MerchShopScene : PackedScene
@export var FuelStorageScene : PackedScene
@export var RepairStationScene : PackedScene
@export var WorkshopScene : PackedScene
@export var TavernScene : PackedScene
@export var RecruitShopScene : PackedScene
@export var MinigameScene : PackedScene

var BoughtFuel : float = 0

var TownSpot : MapSpot
var TownBG : TownBackground
signal TransactionFinished(BFuel : float,  Ship : MapShip, TradeScene : TownScene)

var LandedShips : Array[MapShip]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Setting up background, different for village/city/capital
	var BackgroundScene = ResourceLoader.load(TownSpot.SpotType.BackgroundFile)
	TownBG = BackgroundScene.instantiate() as TownBackground
	$SubViewportContainer/SubViewport.add_child(TownBG)
	TownBG.PositionChanged.connect(_on_town_background_position_changed)
	#Set the port's name on the UI along with the town's buffs
	PortName.text = TownSpot.GetSpotName() + " City Port"
	Population.text = "Population : {0}".format([snapped(TownSpot.Population, 1000)])
	SetTownBuffs()
	
	UISoundMan.GetInstance().Refresh()

func SetTownBuffs() -> void:
	#RepairButton.visible = TownSpot.HasRepair()
	#WorkshopButton.visible = TownSpot.HasUpgrade()
	RecruitButton.visible = TownSpot.HasRecruit()
	RecruitButton2.visible = TownSpot.HasRecruit()
	
	var Text : String = ""
	if (TownSpot.HasFuel()):
		Text += "[p][img={32}x{32}]res://Assets/Items/Fuel.png[/img] REDUCED REFUEL TIME/COST"
	if (TownSpot.HasRepair()):
		Text += "[p][img={32}x{32}]res://Assets/Items/Wrench.png[/img] REDUCED REPAIR TIME/COST"
	if (TownSpot.HasUpgrade()):
		Text += "[p][img={32}x{32}]res://Assets/Items/cubeforcesmol.png[/img] REDUCED UPGRADE TIME/COST"
	if (TownSpot.HasRecruit()):
		Text += "[p][img={32}x{32}]res://Assets/Items/upgrade.png[/img] AVAILABLE RECRUITS"
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
	ActionTracker.OnActionCompleted(ActionTracker.Action.FUEL_SHOP)

func OnRepairStationPressed() -> void:
	var Scene = RepairStationScene.instantiate() as RepairStation
	add_child(Scene)

	Scene.Init(TownSpot.HasRepair(), LandedShips)
	#Scene.FuelTransactionFinished.connect(FuelExchangeFinished)
	ActionTracker.OnActionCompleted(ActionTracker.Action.REPAIR_SHOP)


func FuelExchangeFinished(Fuel : float) -> void:
	BoughtFuel = Fuel

func On_Recruit_Pressed() -> void:
	var tavern = TavernScene.instantiate() as Tavern
	add_child(tavern)
	tavern.Arcade.connect(OpenArcade)
	tavern.RecShop.connect(OpenRecruitShop)

func OpenRecruitShop() -> void:
	if (TownSpot.Recruits.size() == 0):
		PopupManager.DoFadeNotif("No recruits available!", null)
	else:
		var RShop = RecruitShopScene.instantiate() as RecruitShop
		add_child(RShop)
		RShop.Init(TownSpot.Recruits)
		RShop.OnCaptainBought.connect(OnShipBought)

func OpenArcade() -> void:
	PlWallet.AddFunds(-1)
	Map.GetInstance().GetScreenUi().TownUi.DropCoins(1)
	var miniGame = MinigameScene.instantiate() as MissileCommandMain
	add_child(miniGame)

func OnUpgradeShopPressed() -> void:
	var WShop = WorkshopScene.instantiate() as WorkShop
	add_child(WShop)
	WShop.ShipSold.connect(OnShipSold)
	WShop.Init(LandedShips, TownSpot.HasUpgrade(), TownSpot.WorkShopMerch)
	ActionTracker.OnActionCompleted(ActionTracker.Action.UPGRADE_SHOP)

func OnMunitionShopToggled() -> void:
	var Scene = MerchShopScene.instantiate() as MerchShop
	add_child(Scene)
	Scene.ItemSold.connect(OnItemSold)
	Scene.ItemBought.connect(OnItemBought)
	Scene.Init(LandedShips, TownSpot.Merch)
	ActionTracker.OnActionCompleted(ActionTracker.Action.MERCH_SHOP)

func OnShipBought(Cap : Captain) -> void:
	var NewCommander : MapShip
	
	for g in LandedShips:
		if (g.Command == null):
			NewCommander = g
			break
			
	var newship = NewCommander.GetDock().AddCaptain(Cap)
	TownSpot.Recruits.erase(Cap)
	LandedShips.append(newship)

func OnShipSold(Ship : MapShip) -> void:
	Ship.Kill()
	LandedShips.erase(Ship)
	#TownSpot


func OnItemSold(It : Item) -> void:
	PopupManager.DoFadeNotif("{0} has been sold".format([It.GetItemName()]))
	
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
	PopupManager.DoFadeNotif("{0} bought".format([It.GetItemName()]))
	
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
	var WorkshopLine : Line2D = WorkshopButton.get_child(0)
	WorkshopLine.set_point_position(1, WorkshopLine.to_local(WorkshopNode.get_child(0).global_position))
	
	var MerchendiseNode = TownBG.GetNodeForPosition(TownBackground.Location.MERCH)
	MerchendiseButton.global_position = MerchendiseNode.global_position
	var MerchLine : Line2D = MerchendiseButton.get_child(0)
	MerchLine.set_point_position(1, MerchLine.to_local(MerchendiseNode.get_child(0).global_position))
	
	var FuelNode = TownBG.GetNodeForPosition(TownBackground.Location.FUEL)
	FuelButton.global_position = FuelNode.global_position
	var FuelLine : Line2D = FuelButton.get_child(0)
	FuelLine.set_point_position(1, FuelLine.to_local(FuelNode.get_child(0).global_position))

	var RepairNode = TownBG.GetNodeForPosition(TownBackground.Location.REPAIR)
	RepairButton.global_position = RepairNode.global_position
	var RepairLine : Line2D = RepairButton.get_child(0)
	RepairLine.set_point_position(1, RepairLine.to_local(RepairNode.get_child(0).global_position))
	
	var RecruitNode = TownBG.GetNodeForPosition(TownBackground.Location.RECRUIT)
	RecruitButton.global_position = RecruitNode.global_position
	var RecruitLine : Line2D = RecruitButton.get_child(0)
	RecruitLine.set_point_position(1, RecruitLine.to_local(RecruitNode.get_child(0).global_position))

	

func _on_button_pressed() -> void:
	TransactionFinished.emit(BoughtFuel, LandedShips, self)

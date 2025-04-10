extends Control

class_name TownScene
@export_group("Merchandise")
@export var Merch : Array[Merchandise]
@export_group("Nodes")
#@export var FundAmm : Label
@export var PortName : Label
@export var PortBuffText : RichTextLabel
@export var FuelPrice : Label
@export var CurrentFuel : Label
@export var FuelBar : ProgressBar
@export var RepairPrice : Label
@export var CurrentHull : Label
@export var HullBar : ProgressBar
@export var ItemPlecement : Control
@export var RepRefPlecement : Control
@export_group("Values")
@export var FuelPricePerTon : float = 100
@export var RepairpricePerRepairValue : float = 100
@export var PlayerWallet : Wallet
@export_group("Scenes")
@export var ItemScene : PackedScene
@export var RestockStation : PackedScene
#"[color=#c19200]

var TownFuel : float = 0
#var PlFunds : float = 0
var PlFuel : float = 0
var PlMaxFuel : float = 0
var BoughtFuel : float = 0

var TownSpot : MapSpot
var PlHull : float = 0
var PlMaxHull : float = 0
var BoughtRepairs : float = 0

signal TransactionFinished(BFuel : float, BRepair : float, Ship : MapShip, TradeScene : TownScene)

var LandedShip : MapShip

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PortName.text = TownSpot.GetSpotName() + " City Port"
	SetTownBuffs()
	
	if (!TownSpot.HasFuel()):
		FuelPricePerTon = 200
	else:
		FuelPricePerTon = 100

	SetFuelData()
	CurrentFuel.text = var_to_str(roundi(PlFuel + BoughtFuel))
	FuelBar.max_value = PlMaxFuel
	FuelBar.value = PlFuel + BoughtFuel
	FuelPrice.text = var_to_str(FuelPricePerTon)
	if (!TownSpot.HasRepair()):
		RepairpricePerRepairValue = 200
	else:
		RepairpricePerRepairValue = 100

	SetHullData()
	CurrentHull.text = var_to_str(roundi(PlHull))
	HullBar.max_value = PlMaxHull
	HullBar.value = PlHull + BoughtRepairs
	RepairPrice.text = var_to_str(RepairpricePerRepairValue)
	
	var Itms = InventoryManager.GetInstance().GetAllItemsInFleet(LandedShip)
	for g in TownSpot.Merch:
		var It = g.It
		for z in Merch:
			if (It == z.It):
				z.Amm = g.Amm
	#signal OnItemBought(It : Item)
#signal OnItemSold(It : Item)
	
	for m : Merchandise in Merch:
		if (m.Amm == 0 and Itms.count(m.It) == 0):
			continue

		var ItScene = ItemScene.instantiate() as TownShopItem
		ItScene.It = m.It
		ItScene.ItPrice = m.Price
		ItScene.ShopAmm = m.Amm
		ItScene.PlAmm = Itms.count(m.It)
		ItScene.LandedShip = LandedShip
		ItScene.connect("OnItemBought", OnItemBought)
		ItScene.connect("OnItemSold", OnItemSold)
		ItemPlecement.visible = true
		ItemPlecement.add_child(ItScene)
	UISoundMan.GetInstance().Refresh()
func SetFuelData():
	PlFuel = LandedShip.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
	PlMaxFuel = LandedShip.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK)
	var plship = LandedShip as MapShip
	var dd = plship.GetDroneDock()
	for g in dd.DockedDrones:
		PlMaxFuel += g.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK)
		PlFuel += g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
func SetHullData():
	PlHull = LandedShip.Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL)
	PlMaxHull = LandedShip.Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL)
	var plship = LandedShip as MapShip
	var dd = plship.GetDroneDock()
	for g in dd.DockedDrones:
		PlMaxHull += g.Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL)
		PlHull += g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL)

func SetTownBuffs() -> void:
	var Text : String
	if (TownSpot.HasFuel()):
		Text += "[p][img]res://Assets/Items/Fuel.png[/img] REFUEL TIME/COST -[p]"
	if (TownSpot.HasRepair()):
		Text += "[img]res://Assets/Items/cubeforce.png[/img] REPAIR TIME/COST -[p]"
	if (TownSpot.HasUpgrade()):
		Text += "[img]res://Assets/Items/materials-science.png[/img] UPGRADE TIME/COST -[p][p]"
	PortBuffText.text = Text
	
func FuelBar_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click") or event is InputEventScreenDrag):
		var rel = event.relative
		var AddedFuel = roundi(((rel.x / 3) * (FuelBar.max_value / 100)))
		UpdateFuelBar(AddedFuel)
	
func RepairBar_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click") or event is InputEventScreenDrag):
		var rel = event.relative
		var AddedRepair = roundi(((rel.x / 3) * (HullBar.max_value / 100)))
		UpdateRepairBar(AddedRepair)
		
func UpdateFuelBar(AddedFuel : float):
	$AudioStreamPlayer.play()
	if (AddedFuel * FuelPricePerTon > PlayerWallet.Funds):
		AddedFuel = PlayerWallet.Funds / FuelPricePerTon
	if (AddedFuel > TownFuel):
		AddedFuel = TownFuel
	var NewPlFuel = PlFuel + BoughtFuel + AddedFuel
	if (NewPlFuel < 0):
		AddedFuel = 0 - (PlFuel + BoughtFuel)
		NewPlFuel = 0
	if (NewPlFuel > PlMaxFuel):
		AddedFuel = PlMaxFuel - (PlFuel + BoughtFuel)
		NewPlFuel = PlMaxFuel
	TownFuel -= AddedFuel
	BoughtFuel += AddedFuel
	PlayerWallet.AddFunds(-(AddedFuel * FuelPricePerTon))
	FuelBar.value = PlFuel + BoughtFuel
	#FundAmm.text = var_to_str(roundi(PlayerWallet.Funds)) + " ₯"
	CurrentFuel.text = var_to_str(roundi(PlFuel + BoughtFuel))
	
func UpdateRepairBar(AddedRepair : float):
	$AudioStreamPlayer.play()
	if (AddedRepair * RepairpricePerRepairValue > PlayerWallet.Funds):
		AddedRepair = PlayerWallet.Funds / RepairpricePerRepairValue
	var NewPlRepair = PlHull + BoughtRepairs + AddedRepair
	
	if (NewPlRepair < PlHull):
		AddedRepair = 0
		NewPlRepair = PlHull + BoughtRepairs

	if (NewPlRepair > PlMaxHull):
		AddedRepair = PlMaxHull - (PlHull + BoughtRepairs)
		NewPlRepair = PlMaxHull

	BoughtRepairs += AddedRepair
	PlayerWallet.AddFunds(-(AddedRepair * RepairpricePerRepairValue))
	HullBar.value = PlHull + BoughtRepairs
	#FundAmm.text = var_to_str(roundi(PlFunds)) + " ₯"
	CurrentHull.text = var_to_str(roundi(PlHull + BoughtRepairs))
func _on_button_pressed() -> void:
	#PlayerWallet.Funds = PlFunds
	TransactionFinished.emit(BoughtFuel, BoughtRepairs, LandedShip, self)
	#queue_free()


func On_MunitionShop_pressed() -> void:
	ItemPlecement.get_parent().visible = true
	RepRefPlecement.visible = false
	$VBoxContainer/HBoxContainer2/Button3.pressed = false

func OnMunitionShopToggled(toggled_on: bool) -> void:
	ItemPlecement.get_parent().visible = toggled_on
	RepRefPlecement.visible = !toggled_on
	$VBoxContainer/HBoxContainer2/Button2.set_pressed_no_signal(toggled_on)
	$VBoxContainer/HBoxContainer2/Button3.set_pressed_no_signal(!toggled_on)

func On_RefRef_Pressed() -> void:
	ItemPlecement.get_parent().visible = false
	RepRefPlecement.visible = true
	$VBoxContainer/HBoxContainer2/Button2.pressed = false

func OnRefuelShopPressed(toggled_on: bool) -> void:
	ItemPlecement.get_parent().visible = !toggled_on
	RepRefPlecement.visible = toggled_on
	$VBoxContainer/HBoxContainer2/Button2.set_pressed_no_signal(!toggled_on)
	$VBoxContainer/HBoxContainer2/Button3.set_pressed_no_signal(toggled_on)

func OnItemSold(It : Item) -> void:
	InventoryManager.GetInstance().RemoveItemFromFleet(It, LandedShip)
	for g in TownSpot.Merch:
		if (g.It == It):
			g.Amm += 1
			break

func OnItemBought(It : Item) -> void:
	InventoryManager.GetInstance().AddItemToFleet(It, LandedShip)
	for g in TownSpot.Merch:
		if (g.It == It):
			g.Amm -= 1
			break


func _on_scroll_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click") or event is InputEventScreenDrag):
		$VBoxContainer/HBoxContainer/Scroll.scroll_vertical -= event.relative.y
		#UpdateShopItemsDetails()
func UpdateShopItemsDetails() -> void:
	for g:TownShopItem in $VBoxContainer/HBoxContainer/Scroll/VBoxContainer.get_children():
		g.ToggleDetails(g.global_position.y > 0 and g.global_position.y < get_viewport_rect().size.y - 150)

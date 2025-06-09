extends PanelContainer

class_name TownFuelStorages

@export var FuelPriceLabel : Label
@export var CurrentFuelLabel : Label
@export var FuelBar : ProgressBar
@export var RepairPriceLabel : Label
@export var CurrentHullLabel : Label
@export var HullBar : ProgressBar

@export var PlayerWallet : Wallet

var FuelPricePerTon : float
var RepairPricePerUnit : float


var PlFuel : float = 0
var PlMaxFuel : float = 0
var PlayerBoughtFuel : float = 0

var PlHull : float = 0
var PlMaxHull : float = 0
var PlayerBoughtRepairs : float = 0

#var AvailableFunds : float = 0

signal FuelTransactionFinished(RemainingReserves : float, BoughtFuel : float, BoughtRepair : float)

func Init(BoughtFuel : float, FuelPrice : float, BoughtRepairs : float, RepairPrice : float, LandedShips : Array[MapShip]) -> void:
	PlayerBoughtFuel = BoughtFuel
	PlayerBoughtRepairs = BoughtRepairs
	FuelPricePerTon = FuelPrice
	RepairPricePerUnit = RepairPrice

	SetFuelData(LandedShips)
	CurrentFuelLabel.text = var_to_str(roundi(PlFuel + BoughtFuel))
	FuelBar.max_value = PlMaxFuel
	FuelBar.value = PlFuel + BoughtFuel
	FuelPriceLabel.text = var_to_str(FuelPricePerTon)

	RepairPricePerUnit = RepairPrice

	SetHullData(LandedShips)
	CurrentHullLabel.text = var_to_str(roundi(PlHull))
	HullBar.max_value = PlMaxHull
	HullBar.value = PlHull + BoughtRepairs
	RepairPriceLabel.text = var_to_str(RepairPricePerUnit)

func SetFuelData(Ships : Array[MapShip]):
	for g in Ships:
		PlMaxFuel += g.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK)
		PlFuel += g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
		
func SetHullData(Ships : Array[MapShip]):
	for g in Ships:
		PlMaxHull += g.Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL)
		PlHull += g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL)
var SpentFunds : int = 0
func UpdateFuelBar(AddedFuel : float):
	#$AudioStreamPlayer.play()
	if (AddedFuel * FuelPricePerTon > PlayerWallet.Funds):
		AddedFuel = PlayerWallet.Funds / FuelPricePerTon
	var NewPlFuel = PlFuel + PlayerBoughtFuel + AddedFuel
	if (NewPlFuel < 0):
		AddedFuel = 0 - (PlFuel + PlayerBoughtFuel)
		NewPlFuel = 0
	if (NewPlFuel > PlMaxFuel):
		AddedFuel = PlMaxFuel - (PlFuel + PlayerBoughtFuel)
		NewPlFuel = PlMaxFuel
		
	PlayerBoughtFuel += AddedFuel
	
	var MoneySpent = AddedFuel * FuelPricePerTon
	if (MoneySpent > 0):
		SpentFunds += (AddedFuel * FuelPricePerTon)
		if (roundi(SpentFunds/1000) > 1):
			Map.GetInstance().GetScreenUi().TownUI.DropCoins(roundi(SpentFunds / 1000))
			SpentFunds = 0
	else:
		SpentFunds += (AddedFuel * FuelPricePerTon)
		var z = roundi(SpentFunds/1000)
		if (z < -1):
			Map.GetInstance().GetScreenUi().TownUI.CoinsReceived(abs(z))
			SpentFunds = 0
	PlayerWallet.AddFunds(-(AddedFuel * FuelPricePerTon))

	#PlayerWallet.AddFunds(-(AddedFuel * FuelPricePerTon))
	FuelBar.value = PlFuel + PlayerBoughtFuel
	#FundAmm.text = var_to_str(roundi(PlayerWallet.Funds)) + " ₯"
	CurrentFuelLabel.text = var_to_str(roundi(PlFuel + PlayerBoughtFuel))
	
func UpdateRepairBar(AddedRepair : float):
	#$AudioStreamPlayer.play()
	if (AddedRepair * RepairPricePerUnit > PlayerWallet.Funds):
		AddedRepair = PlayerWallet.Funds / RepairPricePerUnit
	var NewPlRepair = PlHull + PlayerBoughtRepairs + AddedRepair
	
	if (NewPlRepair < PlHull):
		AddedRepair = 0
		NewPlRepair = PlHull + PlayerBoughtRepairs

	if (NewPlRepair > PlMaxHull):
		AddedRepair = PlMaxHull - (PlHull + PlayerBoughtRepairs)
		NewPlRepair = PlMaxHull

	PlayerBoughtRepairs += AddedRepair
	
	PlayerWallet.AddFunds(-(AddedRepair * RepairPricePerUnit))
	#PlayerWallet.AddFunds(-(AddedRepair * RepairpricePerRepairValue))
	HullBar.value = PlHull + PlayerBoughtRepairs
	#FundAmm.text = var_to_str(roundi(PlFunds)) + " ₯"
	CurrentHullLabel.text = var_to_str(roundi(PlHull + PlayerBoughtRepairs))

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

func _on_leave_fuel_storage_pressed() -> void:
	FuelTransactionFinished.emit(PlayerBoughtFuel, PlayerBoughtRepairs)
	queue_free()

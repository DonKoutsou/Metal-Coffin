extends VBoxContainer

class_name CaptainRestockStation


var Walet : Wallet
@export var _FuelPricePerTon : float = 100
@export var _RepairpricePerRepairValue : float = 100

@export var FuelPrice : Label
@export var CurrentFuel : Label
@export var FuelBar : ProgressBar
@export var RepairPrice : Label
@export var CurrentHull : Label
@export var HullBar : ProgressBar

var CapBoughtFuel : float
var CapBoughtRepairs : float
var PlFuel : float = 0
var PlMaxFuel : float = 0
var PlHull : float = 0
var PlMaxHull : float = 0
var LandedShip : MapShip

signal FuelBought(NewAmm : float)
signal RepairBought(NewAmm : float)

func SetData(Ship : MapShip, FuelPricePerTon : float, RepairpricePerRepairValue : float) -> void:
	LandedShip = Ship
	
	_FuelPricePerTon = FuelPricePerTon
	_RepairpricePerRepairValue = RepairpricePerRepairValue
	
	SetFuelData()
	CurrentFuel.text = var_to_str(roundi(PlFuel + CapBoughtFuel))
	FuelBar.max_value = PlMaxFuel
	FuelBar.value = PlFuel + CapBoughtFuel
	FuelPrice.text = var_to_str(_FuelPricePerTon)
	
	
	SetHullData()
	CurrentHull.text = var_to_str(roundi(PlHull))
	HullBar.max_value = PlMaxHull
	HullBar.value = PlHull + CapBoughtRepairs
	RepairPrice.text = var_to_str(_RepairpricePerRepairValue)

func SetFuelData():
	PlFuel = LandedShip.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
	PlMaxFuel = LandedShip.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK)
	#var plship = LandedShip as MapShip
	#var dd = plship.GetDroneDock()
	#for g in dd.DockedDrones:
		#PlMaxFuel += g.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK)
		#PlFuel += g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
func SetHullData():
	PlHull = LandedShip.Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL)
	PlMaxHull = LandedShip.Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL)
	#var plship = LandedShip as MapShip
	#var dd = plship.GetDroneDock()
	#for g in dd.DockedDrones:
		#PlMaxHull += g.Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL)
		#PlHull += g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL)

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
	if (AddedFuel * _FuelPricePerTon > Walet.Funds):
		AddedFuel = Walet.Funds / _FuelPricePerTon
	#if (AddedFuel > TownFuel):
		#AddedFuel = TownFuel
		
	var NewPlFuel = PlFuel + CapBoughtFuel + AddedFuel
	if (NewPlFuel < 0):
		AddedFuel = 0 - (PlFuel + CapBoughtFuel)
		NewPlFuel = 0
	if (NewPlFuel > PlMaxFuel):
		AddedFuel = PlMaxFuel - (PlFuel + CapBoughtFuel)
		NewPlFuel = PlMaxFuel
	#TownFuel -= AddedFuel
	CapBoughtFuel += AddedFuel
	Walet.AddFunds(-(AddedFuel * _FuelPricePerTon))
	FuelBar.value = PlFuel + CapBoughtFuel
	#FundAmm.text = var_to_str(roundi(PlayerWallet.Funds)) + " ₯"
	CurrentFuel.text = var_to_str(roundi(PlFuel + CapBoughtFuel))
	
func UpdateRepairBar(AddedRepair : float):
	if (AddedRepair * _RepairpricePerRepairValue > Walet.Funds):
		AddedRepair = Walet.Funds / _RepairpricePerRepairValue
	var NewPlRepair = PlHull + CapBoughtRepairs + AddedRepair
	
	if (NewPlRepair < PlHull):
		AddedRepair = 0
		NewPlRepair = PlHull + CapBoughtRepairs

	if (NewPlRepair > PlMaxHull):
		AddedRepair = PlMaxHull - (PlHull + CapBoughtRepairs)
		NewPlRepair = PlMaxHull

	CapBoughtRepairs += AddedRepair
	Walet.AddFunds(-(AddedRepair * _RepairpricePerRepairValue))
	HullBar.value = PlHull + CapBoughtRepairs
	#FundAmm.text = var_to_str(roundi(PlFunds)) + " ₯"
	CurrentHull.text = var_to_str(roundi(PlHull + CapBoughtRepairs))

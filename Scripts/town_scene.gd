extends Control

class_name TownScene

@export var FuelPricePerTon : float = 100
@export var RepairpricePerRepairValue : float = 100

var TownFuel : float = 0
var PlFunds : float = 0
var PlFuel : float = 0
var PlMaxFuel : float = 0
var BoughtFuel : float = 0
var HasFuel : bool = false
var HasRepair : bool = false

var PlHull : float = 0
var PlMaxHull : float = 0
var BoughtRepairs : float = 0

signal TransactionFinished(BFuel : float, BRepair : float, NewCurrency : float)

var LandedShip : MapShip

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PlFunds = ShipData.GetInstance().GetStat("FUNDS").GetCurrentValue()
	$VBoxContainer2/HBoxContainer2/FundAmm.text = var_to_str(roundi(PlFunds)) + " ₯"
	if (!HasFuel):
		FuelPricePerTon = 200
	else:
		FuelPricePerTon = 100

	if (LandedShip is PlayerShip):
		SetFuelData()
	else :
		SetDroneFuelData()
	$VBoxContainer2/VBoxContainer/HBoxContainer/HBoxContainer/FuelAmm.text = var_to_str(roundi(PlFuel + BoughtFuel))
	$VBoxContainer2/VBoxContainer/ProgressBar.max_value = PlMaxFuel
	$VBoxContainer2/VBoxContainer/ProgressBar.value = PlFuel + BoughtFuel
	$VBoxContainer2/VBoxContainer/HBoxContainer/HBoxContainer2/TonPrice.text = var_to_str(FuelPricePerTon)
	if (!HasRepair):
		RepairpricePerRepairValue = 200
	else:
		RepairpricePerRepairValue = 100
	
	if (LandedShip is PlayerShip):
		SetHullData()
	else :
		SetDroneHullData()
	$VBoxContainer2/VBoxContainer2/HBoxContainer/HBoxContainer/HullAmm.text = var_to_str(roundi(PlHull))
	$VBoxContainer2/VBoxContainer2/ProgressBar.max_value = PlMaxHull
	$VBoxContainer2/VBoxContainer2/ProgressBar.value = PlHull + BoughtRepairs
	$VBoxContainer2/VBoxContainer2/HBoxContainer/HBoxContainer2/RepairPrice.text = var_to_str(RepairpricePerRepairValue)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

func SetFuelData():
	PlFuel = ShipData.GetInstance().GetStat("FUEL").GetCurrentValue()
	PlMaxFuel = ShipData.GetInstance().GetStat("FUEL").GetStat()
	var plship = LandedShip as PlayerShip
	var dd = plship.GetDroneDock()
	for g in dd.DockedDrones:
		PlMaxFuel += g.Cpt.GetStatValue("FUEL_TANK")
		PlFuel += g.Cpt.GetStat("FUEL_TANK").CurrentVelue
	
func SetHullData():
	PlHull = ShipData.GetInstance().GetStat("HULL").GetCurrentValue()
	PlMaxHull = ShipData.GetInstance().GetStat("HULL").GetStat()
	var plship = LandedShip as PlayerShip
	var dd = plship.GetDroneDock()
	for g in dd.DockedDrones:
		PlMaxHull += g.Cpt.GetStatValue("HULL")
		PlHull += g.Cpt.GetStat("HULL").CurrentVelue

func SetDroneFuelData():
	PlFuel = LandedShip.Cpt.GetStat("FUEL_TANK").CurrentVelue
	PlMaxFuel = LandedShip.Cpt.GetStatValue("FUEL_TANK")
	var plship = LandedShip as Drone
	var dd = plship.GetDroneDock()
	for g in dd.DockedDrones:
		PlMaxFuel += g.Cpt.GetStatValue("FUEL_TANK")
		PlFuel += g.Cpt.GetStat("FUEL_TANK").CurrentVelue
func SetDroneHullData():
	PlHull = LandedShip.Cpt.GetStat("HULL").CurrentVelue
	PlMaxHull = LandedShip.Cpt.GetStat("HULL").GetStat()
	var plship = LandedShip as Drone
	var dd = plship.GetDroneDock()
	for g in dd.DockedDrones:
		PlMaxHull += g.Cpt.GetStatValue("HULL")
		PlHull += g.Cpt.GetStat("HULL").CurrentVelue
	
func FuelBar_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		var rel = event.relative
		var AddedFuel = roundi(((rel.x / 3) * ($VBoxContainer2/VBoxContainer/ProgressBar.max_value / 100)))
		UpdateFuelBar(AddedFuel)
	if (event is InputEventScreenDrag):
		var rel = event.relative
		var AddedFuel = roundi(((rel.x / 3) * ($VBoxContainer2/VBoxContainer/ProgressBar.max_value / 100)))
		UpdateFuelBar(AddedFuel)
func RepairBar_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		var rel = event.relative
		var AddedRepair = roundi(((rel.x / 3) * ($VBoxContainer2/VBoxContainer/ProgressBar.max_value / 100)))
		UpdateRepairBar(AddedRepair)
	if (event is InputEventScreenDrag):
		var rel = event.relative
		var AddedRepair = roundi(((rel.x / 3) * ($VBoxContainer2/VBoxContainer/ProgressBar.max_value / 100)))
		UpdateRepairBar(AddedRepair)
		
func UpdateFuelBar(AddedFuel : float):
	if (AddedFuel * FuelPricePerTon > PlFunds):
		AddedFuel = PlFunds / FuelPricePerTon
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
	PlFunds -= AddedFuel * FuelPricePerTon
	$VBoxContainer2/VBoxContainer/ProgressBar.value = PlFuel + BoughtFuel
	$VBoxContainer2/HBoxContainer2/FundAmm.text = var_to_str(roundi(PlFunds)) + " ₯"
	$VBoxContainer2/VBoxContainer/HBoxContainer/HBoxContainer/FuelAmm.text = var_to_str(roundi(PlFuel + BoughtFuel))
	
func UpdateRepairBar(AddedRepair : float):
	if (AddedRepair * RepairpricePerRepairValue > PlFunds):
		AddedRepair = PlFunds / RepairpricePerRepairValue
	
	#if (AddedRepair < 0):
		#AddedRepair = 0
	var NewPlRepair = PlHull + BoughtRepairs + AddedRepair
	
	if (NewPlRepair < PlHull):
		AddedRepair = 0
		NewPlRepair = PlHull + BoughtRepairs

	if (NewPlRepair > PlMaxHull):
		AddedRepair = PlMaxHull - (PlHull + BoughtRepairs)
		NewPlRepair = PlMaxHull

	BoughtRepairs += AddedRepair
	PlFunds -= AddedRepair * RepairpricePerRepairValue
	$VBoxContainer2/VBoxContainer2/ProgressBar.value = PlHull + BoughtRepairs
	$VBoxContainer2/HBoxContainer2/FundAmm.text = var_to_str(roundi(PlFunds)) + " ₯"
	$VBoxContainer2/VBoxContainer2/HBoxContainer/HBoxContainer/HullAmm.text = var_to_str(roundi(PlHull + BoughtRepairs))
func _on_button_pressed() -> void:
	TransactionFinished.emit(BoughtFuel, BoughtRepairs, PlFunds)
	queue_free()

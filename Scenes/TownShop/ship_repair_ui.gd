extends PanelContainer

class_name ShipRepairUI

@export var RepairPriceLabel : Label
@export var CurrentHullLabel : Label
@export var HullBar : ProgressBar
@export var CaptainNameLabel : Label

@export var PlayerWallet : Wallet

var RepairPricePerUnit : float
var PlHull : float = 0
var PlMaxHull : float = 0
var CurrentShip : Captain

var SpentFunds : float

func Init(Ship : Captain, HasRepair : bool) -> void:
	CaptainNameLabel.text = Ship.GetCaptainName()
	CurrentShip = Ship
	RepairPricePerUnit = Ship.GetStatFinalValue(STAT_CONST.STATS.REPAIR_PRICE)
	if (HasRepair):
		RepairPricePerUnit /= 2

	SetHullData(Ship)
	CurrentHullLabel.text = var_to_str(roundi(PlHull))
	HullBar.max_value = PlMaxHull
	HullBar.set_value_no_signal(PlHull + Ship.Repair_Parts)
	RepairPriceLabel.text = var_to_str(RepairPricePerUnit)

func SetHullData(Ship : Captain):
	PlMaxHull += Ship.GetStatFinalValue(STAT_CONST.STATS.HULL)
	PlHull += Ship.GetStatCurrentValue(STAT_CONST.STATS.HULL)

func UpdateRepairBar(AddedRepair : float):
	#$AudioStreamPlayer.play()
	if (AddedRepair * RepairPricePerUnit > PlayerWallet.Funds):
		AddedRepair = PlayerWallet.Funds / RepairPricePerUnit
	var NewPlRepair = PlHull + CurrentShip.Repair_Parts + AddedRepair
	
	if (NewPlRepair < PlHull):
		AddedRepair = 0
		NewPlRepair = PlHull + CurrentShip.Repair_Parts

	if (NewPlRepair > PlMaxHull):
		AddedRepair = PlMaxHull - (PlHull + CurrentShip.Repair_Parts)
		NewPlRepair = PlMaxHull

	CurrentShip.Repair_Parts += AddedRepair
	
	var MoneySpent = AddedRepair * RepairPricePerUnit
	if (MoneySpent > 0):
		SpentFunds += MoneySpent
		if (roundi(SpentFunds/1000) > 1):
			Map.GetInstance().GetScreenUi().TownUi.DropCoins(roundi(SpentFunds / 1000))
			SpentFunds = 0
	else:
		SpentFunds += MoneySpent
		var z = roundi(SpentFunds/1000)
		if (z < -1):
			Map.GetInstance().GetScreenUi().TownUi.CoinsReceived(abs(z))
			SpentFunds = 0
			
	if (MoneySpent > 0):
		AchievementManager.GetInstance().IncrementStatFloat("REPAM", MoneySpent)
	
	PlayerWallet.AddFunds(-MoneySpent)
	#PlayerWallet.AddFunds(-(AddedRepair * RepairpricePerRepairValue))
	HullBar.value = PlHull + CurrentShip.Repair_Parts
	#FundAmm.text = var_to_str(roundi(PlFunds)) + " ₯"
	CurrentHullLabel.text = var_to_str(roundi(PlHull + CurrentShip.Repair_Parts))

func RepairBar_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click") or event is InputEventScreenDrag):
		var rel = event.relative
		var AddedRepair = roundi(((rel.x / 3) * (HullBar.max_value / 100)))
		UpdateRepairBar(AddedRepair)

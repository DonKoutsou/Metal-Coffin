extends PanelContainer

class_name TownFuelStorages

@export var FuelPriceLabel : Label
@export var CurrentFuelLabel : Label
@export var FuelBar : ProgressBar
@export var PlayerWallet : Wallet

var FuelPricePerTon : float


var PlFuel : float = 0
var PlMaxFuel : float = 0
var PlayerBoughtFuel : float = 0

signal FuelTransactionFinished(BoughtFuel : float)

func Init(BoughtFuel : float, FuelPrice : float, LandedShips : Array[MapShip]) -> void:
	PlayerBoughtFuel = BoughtFuel
	FuelPricePerTon = FuelPrice

	SetFuelData(LandedShips)
	CurrentFuelLabel.text = var_to_str(roundi(PlFuel + BoughtFuel))
	FuelBar.max_value = PlMaxFuel
	FuelBar.value = PlFuel + BoughtFuel
	FuelPriceLabel.text = var_to_str(FuelPricePerTon)

func SetFuelData(Ships : Array[MapShip]):
	for g in Ships:
		PlMaxFuel += g.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK)
		PlFuel += g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
		

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

	PlayerWallet.AddFunds(-MoneySpent)
	if (MoneySpent > 0):
		AchievementManager.GetInstance().IncrementStatFloat("FUELAM", MoneySpent)

	#PlayerWallet.AddFunds(-(AddedFuel * FuelPricePerTon))
	FuelBar.value = PlFuel + PlayerBoughtFuel
	#FundAmm.text = var_to_str(roundi(PlayerWallet.Funds)) + " ₯"
	CurrentFuelLabel.text = var_to_str(roundi(PlFuel + PlayerBoughtFuel))

func FuelBar_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click") or event is InputEventScreenDrag):
		var rel = event.relative
		var AddedFuel = roundi(((rel.x / 3) * (FuelBar.max_value / 100)))
		UpdateFuelBar(AddedFuel)

func _on_leave_fuel_storage_pressed() -> void:
	FuelTransactionFinished.emit(PlayerBoughtFuel)
	queue_free()

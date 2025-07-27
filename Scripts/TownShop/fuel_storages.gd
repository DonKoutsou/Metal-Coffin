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

var Spots : Dictionary[MapSpot, Vector2]
var Ships : Array[MapShip]
var Rng = 0

func _draw() -> void:
	var font = load("res://Fonts/DOTMBold.TTF") as Font
	for g in Spots:
		if (!g.SpotType.VisibleOnStart and !g.Seen):
			continue
		for z in Spots:
			if (g.NeighboringCities.has(z.GetSpotName())):
				draw_line(Spots[g], Spots[z], Color(1, 1, 1, 0.1), 3)
		draw_circle(Spots[g], 2, Color(1,1,1), true)
		var textpos = Spots[g]
		textpos.y -= 10
		textpos.x -= (g.GetSpotName().length() / 2) * 15
		var SpotString = g.GetSpotName()
		
		draw_string(font, textpos, SpotString, HORIZONTAL_ALIGNMENT_CENTER, -1, 16,  Color(1, 1,1))
		if (g.HasFuel()):
			draw_texture_rect(load("res://Assets/Items/Fuel.png"), Rect2(Vector2(textpos.x - 20, textpos.y - 14), Vector2(16,16)), false, Color("a29752"))
			#draw_string(font, Vector2(textpos.x - 18, textpos.y + 16), "Fuel Depot", HORIZONTAL_ALIGNMENT_CENTER, -1, 16,  Color(1, 1,1))
	draw_circle(get_viewport_rect().size / 2, Rng / 15, Color(0.3, 0.7, 0.915), false, 4)

func RedrawThing() -> void:
	Rng = 0
	for g in Ships:
		if (g.Command == null):
			Rng += g.GetFuelRangeWithExtraFuel(PlayerBoughtFuel)
	$VBoxContainer/VBoxContainer/Label2.text = "Fleet Range : {0}km".format([roundi(Rng)])
	queue_redraw()

func Init(BoughtFuel : float, FuelPrice : float, LandedShips : Array[MapShip], Pos : MapSpot) -> void:
	var CenterSpot = Pos.global_position
	var SpotsInRange = Helper.GetInstance().GetSpotsCloserThan(Pos.global_position, 64000000)
	Spots[Pos] = get_viewport_rect().size / 2
	for g in SpotsInRange:
		if (g == Pos):
			continue
		var Spotpos = g.global_position - CenterSpot
		Spots[g] = (get_viewport_rect().size / 2) + (Spotpos / 15)
		
	for g in LandedShips:
		if (g.Command == null):
			Rng += g.GetFuelRangeWithExtraFuel(BoughtFuel)
	#var Rng = LandedShips[0].GetFuelRange()
	queue_redraw()
	
	$VBoxContainer/VBoxContainer/Label2.text = "Fleet Range : {0}km".format([roundi(Rng)])
	
	Ships = LandedShips
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
	
	RedrawThing()
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

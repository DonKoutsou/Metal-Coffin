extends Node
class_name World
@export var ShipDat : ShipData
@export var scene :PackedScene
@export var BattleScene : PackedScene
@export var StartingShip : BaseShip

@onready var Mapz = $CanvasLayer/Map as Map
@onready var timer: Timer = $CanvasLayer/Timer
@onready var pause_label: Label = $CanvasLayer2/PauseLabel

@onready var oxygen_bar: ProgressBar = $CanvasLayer/Stat_Panel/Stat_H_Container/Oxygen_Container/HBoxContainer/Oxygen_Bar
@onready var player_hp: ProgressBar = $CanvasLayer/Stat_Panel/Stat_H_Container/HP_Container/HBoxContainer/PlayerHP
@onready var hull_hp: ProgressBar = $CanvasLayer/Stat_Panel/Stat_H_Container/Hull_HP_Container/HBoxContainer/HullHp
@onready var fuel_bar: ProgressBar = $CanvasLayer/Stat_Panel/Stat_H_Container/Fuel_Container/HBoxContainer/Fuel_Bar
@onready var inventory: Inventory = $CanvasLayer/Inventory

var Runningstage = 0
func _enter_tree() -> void:
	
	ShipDat.ApplyShipStats(StartingShip.Buffs)
func _ready() -> void:
	Mapz.connect("StageSellected", PrepareForJourney)
	Mapz.connect("StageSearched", StageSearch)
	
	player_hp.max_value = ShipDat.GetStat("HP").GetStat()
	player_hp.value = ShipDat.GetStat("HP").GetCurrentValue()
	(player_hp.get_child(0) as Label).text = var_to_str(roundi(ShipDat.GetStat("HP").GetCurrentValue())) + "/" + var_to_str(roundi(ShipDat.GetStat("HP").GetStat()))
	fuel_bar.max_value = ShipDat.GetStat("FUEL").GetStat()
	fuel_bar.value = ShipDat.GetStat("FUEL").GetCurrentValue()
	(fuel_bar.get_child(0) as Label).text = var_to_str(roundi(ShipDat.GetStat("FUEL").GetCurrentValue())) + "/" + var_to_str(roundi(ShipDat.GetStat("FUEL").GetStat()))
	hull_hp.max_value = ShipDat.GetStat("HULL").GetStat()
	hull_hp.value = ShipDat.GetStat("HULL").GetCurrentValue()
	(hull_hp.get_child(0) as Label).text = var_to_str(roundi(ShipDat.GetStat("HULL").GetCurrentValue())) + "/" + var_to_str(roundi(ShipDat.GetStat("HULL").GetStat()))
	oxygen_bar.max_value = ShipDat.GetStat("OXYGEN").GetStat()
	oxygen_bar.value = ShipDat.GetStat("OXYGEN").GetCurrentValue()
	(oxygen_bar.get_child(0) as Label).text = var_to_str(roundi(ShipDat.GetStat("OXYGEN").GetCurrentValue())) + "/" + var_to_str(roundi(ShipDat.GetStat("OXYGEN").GetStat()))
	set_physics_process(false)
	
func OnItemAdded(It : Item) -> void:
	if (It is ShipPart):
		ItemBuffStat(It.UpgradeName, It.UpgradeAmm)
func OnItemRemoved(It : Item) -> void:
	if (It is ShipPart):
		ItemBuffStat(It.UpgradeName, -It.UpgradeAmm)
		
func ItemBuffStat(UpName : String, UPvalue : float) -> void:
	ShipDat.GetStat(UpName).StatItemBuff += UPvalue
	if (UpName == "VIZ_RANGE"):
		Mapz.UpdateVizRange(ShipDat.GetStat("VIZ_RANGE").GetStat())
	if (UpName == "ANALYZE_RANGE"):
		Mapz.UpdateAnalyzerRange(ShipDat.GetStat("ANALYZE_RANGE").GetCurrentValue())
	else :if (UpName == "FUEL"):
		var FuelTankSize = ShipDat.GetStat("FUEL").GetStat()
		fuel_bar.max_value = FuelTankSize
		if (FuelTankSize < ShipDat.GetStat("FUEL").GetCurrentValue()):
			UpdateFuel(FuelTankSize)
		(fuel_bar.get_child(0) as Label).text = var_to_str(roundi(ShipDat.GetStat("FUEL").GetCurrentValue())) + "/" + var_to_str(roundi(FuelTankSize))
	else :if (UpName == "FUEL_EFFICIENCY"):
		Mapz.UpdateFuelRange(ShipDat.GetStat("FUEL").GetCurrentValue(), ShipDat.GetStat("FUEL_EFFICIENCY").GetCurrentValue())
	else :if (UpName == "OXYGEN"):
		var Oxygentank = ShipDat.GetStat("OXYGEN").GetStat()
		oxygen_bar.max_value = Oxygentank
		if (Oxygentank < ShipDat.GetStat("OXYGEN").GetCurrentValue()):
			UpdateOxygen(ShipDat.GetStat("OXYGEN").GetStat())
		(oxygen_bar.get_child(0) as Label).text = var_to_str(roundi(ShipDat.GetStat("OXYGEN").GetCurrentValue())) + "/" + var_to_str(roundi(Oxygentank))
		
func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("Pause")):
		var paused = get_tree().paused
		get_tree().paused = !paused
		pause_label.visible = !paused
		
func StartFight(PossibleReward : Array[Item]) -> void:
	var BScene = BattleScene.instantiate() as Battle
	BScene.SupplyReward = PossibleReward
	BScene.PlayerHp = ShipDat.HP
	$CanvasLayer.add_child(BScene)
	BScene.connect("OnBattleEnded", BattleEnded)

func BattleEnded(Resault : bool, RemainingHP : int, SupplyRew : Array[Item]) -> void:
	ShipDat.HP = RemainingHP
	if (Resault):
		UpdateSupplies(SupplyRew)
		UpdateHP(RemainingHP)
	else :
		GameLost("You have died")

func UpdateSupplies(supps : Array[Item]) -> void:
	inventory.AddItems(supps)
func UpdateHP(NewHP : float) -> void:
	ShipDat.GetStat("HP").CurrentVelue = NewHP
	player_hp.value = NewHP
	(player_hp.get_child(0) as Label).text = var_to_str(roundi(ShipDat.GetStat("HP").GetCurrentValue())) + "/" + var_to_str(roundi(ShipDat.GetStat("HP").GetStat()))
func UpdateHullHP(NewHP : int) -> void:
	ShipDat.GetStat("HULL").CurrentVelue = NewHP
	hull_hp.value = NewHP
	(hull_hp.get_child(0) as Label).text = var_to_str(roundi(ShipDat.GetStat("HULL").GetCurrentValue())) + "/" + var_to_str((roundi(ShipDat.GetStat("HULL").GetStat())))
func UpdateFuel(NewFuel : float) -> void:
	ShipDat.GetStat("FUEL").CurrentVelue = NewFuel
	fuel_bar.value = NewFuel
	(fuel_bar.get_child(0) as Label).text = var_to_str(roundi(ShipDat.GetStat("FUEL").GetCurrentValue())) + "/" + var_to_str((roundi(ShipDat.GetStat("FUEL").GetStat())))
	Mapz.ToggleClose()
	Mapz.UpdateFuelRange(ShipDat.GetStat("FUEL").GetCurrentValue(), ShipDat.GetStat("FUEL_EFFICIENCY").GetStat())
func UpdateOxygen(NewO2 : float) -> void:
	ShipDat.GetStat("OXYGEN").CurrentVelue = NewO2
	oxygen_bar.value = NewO2
	(oxygen_bar.get_child(0) as Label).text = var_to_str(roundi(ShipDat.GetStat("OXYGEN").GetCurrentValue())) + "/" + var_to_str((roundi(ShipDat.GetStat("OXYGEN").GetStat())))
var fueltoConsume
var StopToFlyTo
func PrepareForJourney(st : MapSpot, stagenum : int, FuelToUse : float, O2ToUse : float):
	StopToFlyTo = st
	Runningstage = stagenum
	if (ShipDat.GetStat("CRYO").GetStat() == 0):
		UpdateOxygen(ShipDat.GetStat("OXYGEN").GetCurrentValue() - O2ToUse)
	if (ShipDat.GetStat("OXYGEN").GetCurrentValue() <= 0):
		GameLost("You have run out of oxygen")
		return
	ConsumeFuel(FuelToUse)
	
func StartStage() -> void:
	var sc = scene.instantiate() as TravelMinigameGame
	sc.EnemyGoal = fueltoConsume
	sc.Hull = ShipDat.GetStat("HULL").GetCurrentValue()
	sc.connect("OnGameEnded", StageDone)
	add_child(sc)
	sc.SetDestinationScene(StopToFlyTo.SpotType.Scene)
	Mapz.visible = false
	$CanvasLayer.visible = false
func ConsumeFuel(Fuel : float) -> void:
	fueltoConsume = Fuel
	ShipDat.GetStat("FUEL").CurrentVelue -= Fuel
	Mapz.ToggleClose()
	set_physics_process(true)
	timer.start()
	
func _physics_process(_delta: float) -> void:
	var newfuel = ShipDat.GetStat("FUEL").GetCurrentValue() + ((timer.time_left/timer.wait_time)  * fueltoConsume)
	Mapz.UpdateFuelRange(newfuel, ShipDat.GetStat("FUEL_EFFICIENCY").GetStat())
	fuel_bar.value = newfuel
	(fuel_bar.get_child(0) as Label).text = var_to_str(roundi(newfuel) ) + "/" + var_to_str((roundi(ShipDat.GetStat("FUEL").GetStat())))

func StageSearch(supplies : Array[Item])-> void:
	inventory.AddItems(supplies)
	UpdateHP(ShipDat.GetStat("HP").GetCurrentValue() - 10)
	UpdateOxygen(ShipDat.GetStat("OXYGEN").GetCurrentValue() - 5)
	if (ShipDat.GetStat("HP").GetCurrentValue() <= 0):
		GameLost("You have died")
	if (ShipDat.GetStat("OXYGEN").GetCurrentValue() <= 0):
		GameLost("You have run out of oxygen")
	#StartFight(supplies)
	
func StageDone(victory : bool, supplies : Array[Item], HullHP : int) -> void:
	if (victory):
		UpdateSupplies(supplies)
		Mapz.StageCleared(Runningstage)
	else :
		Mapz.StageFailed()
		GameLost("Your ship got destroyed")
		return
	UpdateHullHP(HullHP)
	Mapz.visible = true
	$CanvasLayer.visible = true
	if (ShipDat.GetStat("OXYGEN").GetCurrentValue() <= 0):
		GameLost("You have run out of oxygen")

func UseItem(It : Item) -> bool:
	if (It.ItemName == "Medical"):
		if (ShipDat.GetStat("HP").GetCurrentValue() == ShipDat.GetStat("HP").GetStat()):
			var dig = AcceptDialog.new()
			add_child(dig)
			dig.dialog_text = "HP is already full"
			dig.popup_centered()
			return false
		else :
			UpdateHP(min(ShipDat.GetStat("HP").GetStat(), ShipDat.GetStat("HP").GetCurrentValue() + 20))
			return true
	else : if (It.ItemName == "Radioactive"):
		if (ShipDat.GetStat("FUEL").CurrentVelue == 100):
			var dig = AcceptDialog.new()
			add_child(dig)
			dig.dialog_text = "Fuel is already full"
			dig.popup_centered()
			return false
		else :
			UpdateFuel(min(ShipDat.GetStat("FUEL").GetStat(), ShipDat.GetStat("FUEL").GetCurrentValue() + 20))
			return true
	else : if (It.ItemName == "Supply"):
		if (ShipDat.GetStat("HULL").GetCurrentValue() == ShipDat.GetStat("HULL").GetStat()):
			var dig = AcceptDialog.new()
			add_child(dig)
			dig.dialog_text = "Hull HP is already full"
			dig.popup_centered()
			return false
		else :
			UpdateHullHP(min(ShipDat.GetStat("HULL").GetStat(), ShipDat.GetStat("HULL").GetCurrentValue() + 20))
			return true
	else : if (It.ItemName == "Oxygen"):
		if (ShipDat.GetStat("OXYGEN").CurrentVelue == ShipDat.GetStat("OXYGEN").GetStat()):
			var dig = AcceptDialog.new()
			add_child(dig)
			dig.dialog_text = "Oxygen is already full"
			dig.popup_centered()
			return false
		else :
			UpdateOxygen(min(ShipDat.GetStat("OXYGEN").GetStat(), ShipDat.GetStat("OXYGEN").GetCurrentValue() + 20))
			return true
	return false

func _on_timer_timeout() -> void:
	set_physics_process(false)
	StartStage()
	
func GameLost(reason : String):
	get_tree().paused = true
	$CanvasLayer2/PanelContainer.visible = true
	$CanvasLayer2/PanelContainer/VBoxContainer/Label.text = reason


func _on_button_pressed() -> void:
	get_tree().quit()

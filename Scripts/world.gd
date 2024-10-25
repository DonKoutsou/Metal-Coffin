extends Node
class_name World
@export var ShipDat : ShipData
@export var scene :PackedScene
@export var BattleScene : PackedScene
@export var StartingShip : BaseShip
@export var ShipTradeShip : PackedScene


@onready var Mapz = $CanvasLayer/Map as Map
@onready var timer: Timer = $CanvasLayer/Timer
@onready var pause_container: PanelContainer = $CanvasLayer2/PauseContainer

var CurrentShip : BaseShip

@onready var oxygen_bar: ProgressBar = $CanvasLayer/Stat_Panel/Stat_H_Container/Oxygen_Container/HBoxContainer/Oxygen_Bar
@onready var player_hp: ProgressBar = $CanvasLayer/Stat_Panel/Stat_H_Container/HP_Container/HBoxContainer/PlayerHP
@onready var hull_hp: ProgressBar = $CanvasLayer/Stat_Panel/Stat_H_Container/Hull_HP_Container/HBoxContainer/HullHp
@onready var fuel_bar: ProgressBar = $CanvasLayer/Stat_Panel/Stat_H_Container/Fuel_Container/HBoxContainer/Fuel_Bar
@onready var inventory: Inventory = $CanvasLayer/Inventory

signal OnGameEnded()
func GetInventory() -> Inventory:
	return $CanvasLayer/Inventory as Inventory
func GetMap() -> Map:
	return $CanvasLayer/Map as Map
var Runningstage = 0
func _enter_tree() -> void:
	GetInventory().UpdateShipInfo(StartingShip)
	ShipDat.ApplyShipStats(StartingShip.Buffs)
	$CanvasLayer/Map.UpdateShipIcon(StartingShip.TopIcon)
	CurrentShip = StartingShip
	ShipDat.GetStat("HP").CurrentVelue = ShipDat.GetStat("HP").GetStat()
func StartShipTrade(NewShip : BaseShip) -> void:
	var tradesc = ShipTradeShip.instantiate() as ShipTrade
	$CanvasLayer.add_child(tradesc)
	tradesc.StartTrade(CurrentShip, NewShip)
	tradesc.connect("OnTradeFinished", ChangeShip)
func ChangeShip(NewShip : BaseShip) -> void:
	if (NewShip == CurrentShip):
		return
	GetInventory().UpdateShipInfo(NewShip)
	ShipDat.RemoveShipStats(CurrentShip.Buffs)
	ShipDat.ApplyShipStats(NewShip.Buffs)
	UpdateShipInventorySice()
	CurrentShip = NewShip
	UpdateBars()
	Mapz.UpdateShipIcon(NewShip.TopIcon)
func UpdateShipInventorySice() -> void:
	GetInventory().UpdateSize()
	pass
func ResetState() -> void:
	for g in ShipDat.Stats.size():
		ShipDat.Stats[g].CurrentVelue = 0
		ShipDat.Stats[g].StatItemBuff = 0
		ShipDat.Stats[g].StatShipBuff = 0
func GetShipSaveData() -> SaveData:
	var dat = SaveData.new()
	dat.DataName = "Ship"
	var Datas : Array[Resource]
	Datas.append(CurrentShip)
	dat.Datas = Datas
	return dat
func LoadData(Data : Resource) -> void:
	var dat = Data as StatSave
	UpdateHP(dat.Value[0])
	UpdateHullHP(dat.Value[1])
	UpdateOxygen(dat.Value[2])
	UpdateFuel(dat.Value[3])

func _ready() -> void:
	Mapz.connect("StageSellected", PrepareForJourney)
	Mapz.connect("StageSearched", StageSearch)
	Mapz.connect("ShipSearched", ShipSearched)
	UpdateBars()
	set_physics_process(false)
	#call_deferred("TestTrade")
func UpdateBars()-> void:
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
func TestTrade() -> void:
	StartShipTrade(load("res://Resources/Ships/Ship2.tres") as BaseShip)
	
func OnItemAdded(It : Item) -> void:
	if (It is ShipPart):
		ShipDat.ApplyShipPartStat(It)
		ItemBuffStat(It.UpgradeName)
func OnItemRemoved(It : Item) -> void:
	if (It is ShipPart):
		ShipDat.RemoveShipPartStat(It)
		ItemBuffStat(It.UpgradeName)
		
func ItemBuffStat(UpName : String) -> void:
	if (UpName == "VIZ_RANGE"):
		$CanvasLayer/Map.UpdateVizRange(ShipDat.GetStat("VIZ_RANGE").GetStat())
	if (UpName == "ANALYZE_RANGE"):
		$CanvasLayer/Map.UpdateAnalyzerRange(ShipDat.GetStat("ANALYZE_RANGE").GetStat())
	else :if (UpName == "FUEL"):
		var FuelTankSize = ShipDat.GetStat("FUEL").GetStat()
		$CanvasLayer/Stat_Panel/Stat_H_Container/Fuel_Container/HBoxContainer/Fuel_Bar.max_value = FuelTankSize
		if (FuelTankSize < ShipDat.GetStat("FUEL").GetCurrentValue()):
			UpdateFuel(FuelTankSize)
		($CanvasLayer/Stat_Panel/Stat_H_Container/Fuel_Container/HBoxContainer/Fuel_Bar.get_child(0) as Label).text = var_to_str(roundi(ShipDat.GetStat("FUEL").GetCurrentValue())) + "/" + var_to_str(roundi(FuelTankSize))
	else :if (UpName == "FUEL_EFFICIENCY"):
		$CanvasLayer/Map.UpdateFuelRange(ShipDat.GetStat("FUEL").GetCurrentValue(), ShipDat.GetStat("FUEL_EFFICIENCY").GetStat())
	else :if (UpName == "OXYGEN"):
		var Oxygentank = ShipDat.GetStat("OXYGEN").GetStat()
		$CanvasLayer/Stat_Panel/Stat_H_Container/Oxygen_Container/HBoxContainer/Oxygen_Bar.max_value = Oxygentank
		if (Oxygentank < ShipDat.GetStat("OXYGEN").GetCurrentValue()):
			UpdateOxygen(ShipDat.GetStat("OXYGEN").GetStat())
		($CanvasLayer/Stat_Panel/Stat_H_Container/Oxygen_Container/HBoxContainer/Oxygen_Bar.get_child(0) as Label).text = var_to_str(roundi(ShipDat.GetStat("OXYGEN").GetCurrentValue())) + "/" + var_to_str(roundi(Oxygentank))
		
func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("Pause")):
		Pause()
func Pause() -> void:
	var paused = get_tree().paused
	get_tree().paused = !paused
	pause_container.visible = !paused
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
	$CanvasLayer/Stat_Panel/Stat_H_Container/Fuel_Container/HBoxContainer/Fuel_Bar.value = NewFuel
	($CanvasLayer/Stat_Panel/Stat_H_Container/Fuel_Container/HBoxContainer/Fuel_Bar.get_child(0) as Label).text = var_to_str(roundi(ShipDat.GetStat("FUEL").GetCurrentValue())) + "/" + var_to_str((roundi(ShipDat.GetStat("FUEL").GetStat())))
	$CanvasLayer/Map.ToggleClose()
	$CanvasLayer/Map.UpdateFuelRange(ShipDat.GetStat("FUEL").GetCurrentValue(), ShipDat.GetStat("FUEL_EFFICIENCY").GetStat())
func UpdateOxygen(NewO2 : float) -> void:
	ShipDat.GetStat("OXYGEN").CurrentVelue = NewO2
	$CanvasLayer/Stat_Panel/Stat_H_Container/Oxygen_Container/HBoxContainer/Oxygen_Bar.value = NewO2
	($CanvasLayer/Stat_Panel/Stat_H_Container/Oxygen_Container/HBoxContainer/Oxygen_Bar.get_child(0) as Label).text = var_to_str(roundi(ShipDat.GetStat("OXYGEN").GetCurrentValue())) + "/" + var_to_str((roundi(ShipDat.GetStat("OXYGEN").GetStat())))
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
	sc.CharacterScene = CurrentShip.ShipScene
	sc.EnemyGoal = fueltoConsume
	sc.Hull = ShipDat.GetStat("HULL").GetCurrentValue()
	sc.HullMax = ShipDat.GetStat("HULL").GetStat()
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
func ShipSearched(Ship : BaseShip):
	StartShipTrade(Ship)
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
	OnGameEnded.emit()


func _on_save_pressed() -> void:
	SaveLoadManager.GetInstance().Save(self)
	var window = AcceptDialog.new()
	add_child(window)
	window.dialog_text = "Save successful"
	window.popup_centered()
func _on_exit_pressed() -> void:
	#ResetState()
	OnGameEnded.emit()

func _on_pause_pressed() -> void:
	Pause()

func _on_return_pressed() -> void:
	Pause()

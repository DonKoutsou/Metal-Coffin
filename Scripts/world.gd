extends Node
class_name World
@export var PlayerDat : PlayerData
@export var scene :PackedScene
@export var BattleScene : PackedScene

@onready var Mapz = $CanvasLayer/Map as Map
@onready var timer: Timer = $CanvasLayer/Timer
@onready var pause_label: Label = $CanvasLayer2/PauseLabel

@onready var oxygen_bar: ProgressBar = $CanvasLayer/Stat_Panel/Stat_H_Container/Oxygen_Container/HBoxContainer/Oxygen_Bar
@onready var player_hp: ProgressBar = $CanvasLayer/Stat_Panel/Stat_H_Container/HP_Container/HBoxContainer/PlayerHP
@onready var hull_hp: ProgressBar = $CanvasLayer/Stat_Panel/Stat_H_Container/Hull_HP_Container/HBoxContainer/HullHp
@onready var fuel_bar: ProgressBar = $CanvasLayer/Stat_Panel/Stat_H_Container/Fuel_Container/HBoxContainer/Fuel_Bar
@onready var inventory: Inventory = $CanvasLayer/Inventory

var Runningstage = 0

func _ready() -> void:
	Mapz.connect("StageSellected", PrepareForJourney)
	Mapz.connect("StageSearched", StageSearch)
	player_hp.max_value = PlayerDat.HP
	player_hp.value = PlayerDat.HP
	(player_hp.get_child(0) as Label).text = var_to_str(PlayerDat.HP) + "/" + var_to_str(100)
	fuel_bar.max_value = PlayerDat.FUEL_TANK_SIZE
	fuel_bar.value = PlayerDat.FUEL
	(fuel_bar.get_child(0) as Label).text = var_to_str(PlayerDat.FUEL) + "/" + var_to_str(PlayerDat.FUEL_TANK_SIZE)
	hull_hp.max_value = PlayerDat.HULL_MAX_HP
	hull_hp.value = PlayerDat.HULLHP
	(hull_hp.get_child(0) as Label).text = var_to_str(PlayerDat.HULLHP) + "/" + var_to_str(PlayerDat.HULL_MAX_HP)
	oxygen_bar.max_value = PlayerDat.OXYGEN_TANK_SIZE
	oxygen_bar.value = PlayerDat.OXYGEN
	(oxygen_bar.get_child(0) as Label).text = var_to_str(PlayerDat.OXYGEN) + "/" + var_to_str(PlayerDat.OXYGEN_TANK_SIZE)
	set_physics_process(false)
	
func Upgrage(UpgradeData : Upgrade) -> void:
	PlayerDat.set(UpgradeData.UpgradeName, PlayerDat.get(UpgradeData.UpgradeName) + UpgradeData.UpgradeStep)
	if (UpgradeData.UpgradeName == "VIZ_RANGE"):
		Mapz.UpdateVizRange(PlayerDat.VIZ_RANGE)
	if (UpgradeData.UpgradeName == "ANALYZE_RANGE"):
		Mapz.UpdateAnalyzerRange(PlayerDat.ANALYZE_RANGE)
	else :if (UpgradeData.UpgradeName == "FUEL_TANK_SIZE"):
		fuel_bar.max_value = PlayerDat.FUEL_TANK_SIZE
		(fuel_bar.get_child(0) as Label).text = var_to_str(roundi(PlayerDat.FUEL)) + "/" + var_to_str(roundi(PlayerDat.FUEL_TANK_SIZE))
	else :if (UpgradeData.UpgradeName == "FUEL_EFFICIENCY"):
		Mapz.UpdateFuelRange(PlayerDat.FUEL, PlayerDat.FUEL_EFFICIENCY)
	else :if (UpgradeData.UpgradeName == "OXYGEN_TANK_SIZE"):
		oxygen_bar.max_value = PlayerDat.OXYGEN_TANK_SIZE
		(oxygen_bar.get_child(0) as Label).text = var_to_str(roundi(PlayerDat.OXYGEN)) + "/" + var_to_str(roundi(PlayerDat.OXYGEN_TANK_SIZE))
		
func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("Pause")):
		var paused = get_tree().paused
		get_tree().paused = !paused
		pause_label.visible = !paused
		
func StartFight(PossibleReward : Array[Item]) -> void:
	var BScene = BattleScene.instantiate() as Battle
	BScene.SupplyReward = PossibleReward
	BScene.PlayerHp = PlayerDat.HP
	$CanvasLayer.add_child(BScene)
	BScene.connect("OnBattleEnded", BattleEnded)

func BattleEnded(Resault : bool, RemainingHP : int, SupplyRew : Array[Item]) -> void:
	PlayerDat.HP = RemainingHP
	if (Resault):
		UpdateSupplies(SupplyRew)
		UpdateHP(RemainingHP)
	else :
		GameLost("You have died")

func UpdateSupplies(supps : Array[Item]) -> void:
	inventory.AddItems(supps)
func UpdateHP(NewHP : int) -> void:
	PlayerDat.HP = NewHP
	player_hp.value = NewHP
	(player_hp.get_child(0) as Label).text = var_to_str(PlayerDat.HP) + "/" + var_to_str(100)
func UpdateHullHP(NewHP : int) -> void:
	PlayerDat.HULLHP = NewHP
	hull_hp.value = NewHP
	(hull_hp.get_child(0) as Label).text = var_to_str(PlayerDat.HULLHP) + "/" + var_to_str((roundi(PlayerDat.HULL_MAX_HP)))
func UpdateFuel(NewFuel : float) -> void:
	PlayerDat.FUEL = NewFuel
	fuel_bar.value = NewFuel
	(fuel_bar.get_child(0) as Label).text = var_to_str(roundi(PlayerDat.FUEL)) + "/" + var_to_str((roundi(PlayerDat.FUEL_TANK_SIZE)))
	Mapz.ToggleClose()
	Mapz.UpdateFuelRange(PlayerDat.FUEL, PlayerDat.FUEL_EFFICIENCY)
func UpdateOxygen(NewO2 : float) -> void:
	PlayerDat.OXYGEN = NewO2
	oxygen_bar.value = NewO2
	(oxygen_bar.get_child(0) as Label).text = var_to_str(roundi(PlayerDat.OXYGEN)) + "/" + var_to_str((roundi(PlayerDat.OXYGEN_TANK_SIZE)))
var fueltoConsume
var StopToFlyTo
func PrepareForJourney(st : MapSpot, stagenum : int, FuelToUse : float, O2ToUse : float):
	StopToFlyTo = st
	Runningstage = stagenum
	ConsumeFuel(FuelToUse)
	UpdateOxygen(PlayerDat.OXYGEN - O2ToUse)
func StartStage() -> void:
	var sc = scene.instantiate() as TravelMinigameGame
	sc.EnemyGoal = fueltoConsume
	sc.Hull = PlayerDat.HULLHP
	sc.connect("OnGameEnded", StageDone)
	add_child(sc)
	sc.SetDestinationScene(StopToFlyTo.SpotType.Scene)
	Mapz.visible = false
	$CanvasLayer.visible = false
func ConsumeFuel(Fuel : float) -> void:
	fueltoConsume = Fuel
	PlayerDat.FUEL -= Fuel
	Mapz.ToggleClose()
	set_physics_process(true)
	timer.start()
	
func _physics_process(_delta: float) -> void:
	var newfuel = PlayerDat.FUEL + ((timer.time_left/timer.wait_time)  * fueltoConsume)
	Mapz.UpdateFuelRange(newfuel, PlayerDat.FUEL_EFFICIENCY)
	fuel_bar.value = newfuel
	(fuel_bar.get_child(0) as Label).text = var_to_str(roundi(newfuel) ) + "/" + var_to_str((roundi(PlayerDat.FUEL_TANK_SIZE)))

func StageSearch(supplies : Array[Item])-> void:
	inventory.AddItems(supplies)
	UpdateHP(PlayerDat.HP - 20)
	UpdateOxygen(PlayerDat.OXYGEN - 10)
	if (PlayerDat.HP == 0):
		GameLost("You have died")
	if (PlayerDat.OXYGEN == 0):
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
	if (PlayerDat.OXYGEN == 0):
		GameLost("You have run out of oxygen")

func UseItem(It : Item) -> bool:
	if (It.ItemName == "Medical"):
		if (PlayerDat.HP == 100):
			return false
		else :
			UpdateHP(min(100, PlayerDat.HP + 20))
			return true
	else : if (It.ItemName == "Radioactive"):
		if (PlayerDat.FUEL == 100):
			return false
		else :
			UpdateFuel(min(PlayerDat.FUEL_TANK_SIZE, PlayerDat.FUEL + 20))
			return true
	else : if (It.ItemName == "Supply"):
		if (PlayerDat.HULLHP == PlayerDat.HULL_MAX_HP):
			return false
		else :
			UpdateHullHP(min(PlayerDat.HULL_MAX_HP, PlayerDat.HULLHP + 20))
			return true
	else : if (It.ItemName == "Oxygen"):
		if (PlayerDat.OXYGEN == PlayerDat.OXYGEN_TANK_SIZE):
			return false
		else :
			UpdateOxygen(min(PlayerDat.OXYGEN_TANK_SIZE, PlayerDat.OXYGEN + 20))
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

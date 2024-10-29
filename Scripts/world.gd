extends Node
class_name World
@export var ShipDat : ShipData
@export var scene :PackedScene
@export var BattleScene : PackedScene
@export var ExplorationScene : PackedScene
@export var StartingShip : BaseShip
@export var ShipTradeShip : PackedScene

@onready var stat_panel: StatPanel = $CanvasLayer/Stat_Panel
@onready var Mapz = $CanvasLayer/Map as Map
@onready var timer: Timer = $CanvasLayer/Timer
@onready var pause_container: PanelContainer = $CanvasLayer2/PauseContainer

var CurrentShip : BaseShip

@onready var inventory: Inventory = $CanvasLayer/Inventory

signal OnGameEnded()
signal StatsUpdated(StatN : String)

func GetInventory() -> Inventory:
	return $CanvasLayer/Inventory as Inventory
	
func GetMap() -> Map:
	return $CanvasLayer/Map as Map
func _exit_tree() -> void:
	ShipDat.RemoveShipStats(CurrentShip.Buffs)
func OnStatsUpdated(StatName : String):
	StatsUpdated.emit(StatName)
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
	StatsUpdated.emit()
	Mapz.UpdateShipIcon(NewShip.TopIcon)
	
func UpdateShipInventorySice() -> void:
	GetInventory().UpdateSize()
	pass
	
func ResetState() -> void:
	for g in ShipDat.Stats.size():
		ShipDat.UpdateStatCurrentValue(ShipDat.Stats[g].StatName, 0)
		#ShipDat.Stats[g].CurrentVelue = 0
		#ShipDat.Stats[g].StatItemBuff = 0
		#ShipDat.Stats[g].StatShipBuff = 0
		
func GetShipSaveData() -> SaveData:
	var dat = SaveData.new()
	dat.DataName = "Ship"
	var Datas : Array[Resource]
	Datas.append(CurrentShip)
	dat.Datas = Datas
	return dat
	
func LoadData(Data : Resource) -> void:
	var dat = Data as StatSave
	UpdateStat(dat.Value[0], "HP")
	UpdateStat(dat.Value[1], "HULL", )
	UpdateStat(dat.Value[2], "OXYGEN")
	UpdateStat(dat.Value[3], "FUEL")

func _ready() -> void:
	Mapz.connect("AsteroidBeltArrival", StartStage)
	#Mapz.connect("StageSellected", PrepareForJourney)
	Mapz.connect("StageSearched", StageSearch)
	Mapz.connect("ShipSearched", ShipSearched)
	set_physics_process(false)
	
	UISoundMan.GetInstance().Refresh()
	#call_deferred("TestTrade")
func _enter_tree() -> void:
	connect("StatsUpdated", $CanvasLayer/Stat_Panel.StatsUp)
	ShipDat.connect("StatsUpdated", OnStatsUpdated)
	
	GetInventory().UpdateShipInfo(StartingShip)
	ShipDat.ApplyShipStats(StartingShip.Buffs)
	$CanvasLayer/Map.UpdateShipIcon(StartingShip.TopIcon)
	CurrentShip = StartingShip
	ShipDat.UpdateStatCurrentValue("HP", ShipDat.GetStat("HP").GetStat())

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
		$CanvasLayer/Map.player_ship.UpdateVizRange(ShipDat.GetStat("VIZ_RANGE").GetStat())
	else :if (UpName == "ANALYZE_RANGE"):
		$CanvasLayer/Map.player_ship.UpdateAnalyzerRange(ShipDat.GetStat("ANALYZE_RANGE").GetStat())
	else :if (UpName == "FUEL_EFFICIENCY" or UpName == "FUEL"):
		$CanvasLayer/Map.player_ship.UpdateFuelRange(ShipDat.GetStat("FUEL").GetCurrentValue(), ShipDat.GetStat("FUEL_EFFICIENCY").GetStat())
	#else :if  (UpName == "FUEL"):
		#$CanvasLayer/Map.UpdateFuelRange(ShipDat.GetStat("FUEL").GetCurrentValue(), ShipDat.GetStat("FUEL_EFFICIENCY").GetStat())
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
	
func StartExploration(Spot : MapSpot) -> void:
	var Escene = ExplorationScene.instantiate() as Exploration
	Escene.PlayerHp = ShipDat.GetStat("HP").CurrentVelue
	Escene.PlayerOxy = ShipDat.GetStat("OXYGEN").CurrentVelue
	$CanvasLayer.add_child(Escene)
	Escene.StartExploration(Spot.SpotType, CurrentShip)
	Escene.connect("OnExplorationEnded", ExplorationEnded)
	if (Spot.SpotType.HasAtmoshere):
		ShipData.GetInstance().UpdateStatCurrentValue("OXYGEN", ShipData.GetInstance().GetStat("OXYGEN").GetStat())
		PopUpManager.GetInstance().DoPopUp("You oxygen tanks have been refilled when entering the atmopshere")

func ExplorationEnded(RemainingHP : int, RemainingOxy : int, SupplyRew : Array[Item]) -> void:
	UpdateStat(RemainingHP, "HP")
	UpdateStat(RemainingOxy, "OXYGEN")
	GetInventory().AddItems(SupplyRew)
func BattleEnded(Resault : bool, RemainingHP : int, SupplyRew : Array[Item]) -> void:
	ShipDat.HP = RemainingHP
	if (Resault):
		GetInventory().AddItems(SupplyRew)
		UpdateStat(RemainingHP, "HP")
	else :
		GameLost("You have died")

func UpdateStat(NewStat : float, StatN : String):
	ShipDat.UpdateStatCurrentValue(StatN, NewStat)
	StatsUpdated.emit(StatN)
	if (StatN == "FUEL"):
		#$CanvasLayer/Map.ToggleClose()
		$CanvasLayer/Map.player_ship.UpdateFuelRange(ShipDat.GetStat("FUEL").GetCurrentValue(), ShipDat.GetStat("FUEL_EFFICIENCY").GetStat())
##Need to gather this around, its shit
var fueltoConsume
var FuelOnDepart
var StopToFlyTo : MapSpot
var PlPos : Vector2
var Traveling = false
func PrepareForJourney(st : MapSpot, stagenum : int, FuelToUse : float, O2ToUse : float):
	StopToFlyTo = st
	PlPos = GetMap().GetPlayerPos()
	GetMap().PlayerLookAt(StopToFlyTo.position)
	Runningstage = stagenum
	timer.wait_time = PlPos.distance_to(StopToFlyTo.position) / 20
	if (ShipDat.GetStat("CRYO").GetStat() == 0):
		if (ShipDat.GetStat("OXYGEN").GetCurrentValue() <= O2ToUse):
			PopUpManager.GetInstance().DoPopUp("Not enough oxygen to do action.")
			return
		UpdateStat(ShipDat.GetStat("OXYGEN").GetCurrentValue() - O2ToUse, "OXYGEN")
		#if (ShipDat.GetStat("OXYGEN").GetCurrentValue() <= 0):
			#GameLost("You have run out of oxygen")
			#return
	if (ShipDat.GetStat("FUEL").CurrentVelue < FuelToUse):
		PopUpManager.GetInstance().DoPopUp("Not enough fuel to do action.")
		return
	ConsumeFuel(FuelToUse)
	Traveling = true

func StartStage() -> void:
	var sc = scene.instantiate() as TravelMinigameGame
	sc.CharacterScene = CurrentShip.ShipScene
	#sc.EnemyGoal = fueltoConsume
	sc.Hull = ShipDat.GetStat("HULL").GetCurrentValue()
	sc.HullMax = ShipDat.GetStat("HULL").GetStat()
	sc.connect("OnGameEnded", StageDone)
	add_child(sc)
	#sc.SetDestinationScene(StopToFlyTo.SpotType.Scene)
	Mapz.visible = false
	$CanvasLayer.visible = false
	Mapz.set_process(false)
	Mapz.set_process_input(false)
	
func ConsumeFuel(Fuel : float) -> void:
	await Mapz.OnLookAtEnded
	fueltoConsume = Fuel
	FuelOnDepart = ShipDat.GetStat("FUEL").GetCurrentValue()
	ShipDat.AddToStatCurrentValue("FUEL", -Fuel)
	set_physics_process(true)
	timer.start()

func _physics_process(_delta: float) -> void:
	var timething = timer.time_left/timer.wait_time
	var timething2 = (timer.wait_time - timer.time_left) / timer.wait_time
	var newfuel = (FuelOnDepart - fueltoConsume) + (timething  * fueltoConsume)
	ShipDat.UpdateStatCurrentValue("FUEL", newfuel)
	Mapz.UpdateFuelRange(newfuel, ShipDat.GetStat("FUEL_EFFICIENCY").GetStat())
	GetMap().SetPlayerPos(PlPos +  (timething2 * (StopToFlyTo.position - PlPos)))
	#fuel_bar.value = newfuel
	#(fuel_bar.get_child(0) as Label).text = var_to_str(roundi(newfuel) ) + "/" + var_to_str((roundi(ShipDat.GetStat("FUEL").GetStat())))
#/////////////////////////////////////////////////////////////////////////////////////

func ShipSearched(Ship : BaseShip):
	StartShipTrade(Ship)
	
func StageSearch(Spt : MapSpot)-> void:
	if (ShipDat.GetStat("OXYGEN").GetCurrentValue() <= 5):
		PopUpManager.GetInstance().DoPopUp("Not enough oxygen to complete action")
		return
	if (ShipDat.GetStat("HP").GetCurrentValue() <= 10):
		PopUpManager.GetInstance().DoPopUp("Not enough HP to complete action")
		return
	if (!Spt.SpotType.CanLand):
		inventory.AddItems(Spt.SpotType.GetSpotDrop())
	else:
		StartExploration(Spt)
	UpdateStat(ShipDat.GetStat("HP").GetCurrentValue() - 10, "HP")
	UpdateStat(ShipDat.GetStat("OXYGEN").GetCurrentValue() - 5, "OXYGEN")
	#if (ShipDat.GetStat("HP").GetCurrentValue() <= 0):
		#GameLost("You have died")
	#if (ShipDat.GetStat("OXYGEN").GetCurrentValue() <= 0):
		#GameLost("You have run out of oxygen")
	
	
var Runningstage = 0
func StageDone(victory : bool, supplies : Array[Item], HullHP : int) -> void:
	if (victory):
		GetInventory().AddItems(supplies)
		#Mapz.Arrival(Runningstage)
	else :
		Mapz.StageFailed()
		GameLost("Your ship got destroyed")
		return
	UpdateStat(HullHP, "HULL")
	Mapz.set_process(true)
	Mapz.set_process_input(true)
	Mapz.visible = true
	$CanvasLayer.visible = true
	if (ShipDat.GetStat("OXYGEN").GetCurrentValue() <= 0):
		GameLost("You have run out of oxygen")

func UseItem(It : UsableItem) -> bool:
	if (Traveling):
		PopUpManager.GetInstance().DoPopUp("Cant use items when traveling.")
		return false
	var statname = It.StatUseName
	if (ShipDat.GetStat(statname).GetCurrentValue() == ShipDat.GetStat(statname).GetStat()):
		PopUpManager.GetInstance().DoPopUp(statname + " is already full")
		return false
	else :
		UpdateStat(min(ShipDat.GetStat(statname).GetStat(), ShipDat.GetStat(statname).GetCurrentValue() + 20), statname)
		return true

func _on_timer_timeout() -> void:
	set_physics_process(false)
	StartStage()
	Traveling = false
	
func GameLost(reason : String):
	get_tree().paused = true
	$CanvasLayer2/PanelContainer.visible = true
	$CanvasLayer2/PanelContainer/VBoxContainer/Label.text = reason

func _on_button_pressed() -> void:
	OnGameEnded.emit()

func _on_save_pressed() -> void:
	SaveLoadManager.GetInstance().Save(self)
	PopUpManager.GetInstance().DoPopUp("Save successful")
	
func _on_exit_pressed() -> void:
	#ResetState()
	OnGameEnded.emit()

func _on_pause_pressed() -> void:
	Pause()

func _on_return_pressed() -> void:
	Pause()

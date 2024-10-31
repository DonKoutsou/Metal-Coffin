extends Node2D
class_name World

@export var ShipDat : ShipData

@export var TraveMinigameScene :PackedScene
@export var BattleScene : PackedScene
@export var ExplorationScene : PackedScene
@export var StartingShip : BaseShip
@export var ShipTradeScene : PackedScene

#ship player is currently using
var CurrentShip : BaseShip
# array holding the strings of the stats that we have already notified the player that are getting low
var StatsNotifiedLow : Array[String] = []

signal OnGameEnded()
signal StatsUpdated(StatN : String)
signal StatGotLow(StatN : String)

func _ready() -> void:
	var map = GetMap()
	map.connect("AsteroidBeltArrival", StartStage)
	map.connect("StageSearched", StageSearch)
	map.connect("ShipSearched", ShipSearched)
	UISoundMan.GetInstance().Refresh()
	#call_deferred("TestTrade")

func _enter_tree() -> void:
	connect("StatsUpdated", $Ingame_UIManager/Stat_Panel.StatsUp)
	connect("StatGotLow", $Ingame_UIManager/Stat_Panel.StatsLow)
	
	ShipDat.connect("StatsUpdated", OnStatsUpdated)
	
	GetInventory().UpdateShipInfo(StartingShip)
	ShipDat.ApplyShipStats(StartingShip.Buffs)
	GetMap().GetPlayerShip().UpdateShipIcon(StartingShip.TopIcon)
	CurrentShip = StartingShip
	ShipDat._UpdateStatCurrentValue("HP", ShipDat.GetStat("HP").GetStat())
	
func _exit_tree() -> void:
	ShipDat.RemoveShipStats(CurrentShip.Buffs)
	
func OnStatsUpdated(StatName : String):
	if (ShipDat.GetStat(StatName).GetCurrentValue() < ShipDat.GetStat(StatName).GetStat() * 0.2):
		if (!StatsNotifiedLow.has(StatName) and !$Map.GetPlayerShip().ShowingNotif()):
			StatsNotifiedLow.append(StatName)
			$Map.GetPlayerShip().OnStatLow(StatName)
			StatGotLow.emit(StatName)
	else:
		if (StatsNotifiedLow.has(StatName)):
			StatsNotifiedLow.remove_at(StatsNotifiedLow.find(StatName))
	StatsUpdated.emit(StatName)
	
func StartShipTrade(NewShip : BaseShip) -> void:
	var tradesc = ShipTradeScene.instantiate() as ShipTrade
	$Ingame_UIManager.add_child(tradesc)
	tradesc.StartTrade(CurrentShip, NewShip)
	tradesc.connect("OnTradeFinished", ChangeShip)
	
func ChangeShip(NewShip : BaseShip) -> void:
	if (NewShip == CurrentShip):
		return
	GetInventory().UpdateShipInfo(NewShip)
	ShipDat.RemoveShipStats(CurrentShip.Buffs)
	ShipDat.ApplyShipStats(NewShip.Buffs)
	GetInventory().UpdateSize()
	GetMap().GetPlayerShip().UpdateShipIcon(NewShip.TopIcon)
	CurrentShip = NewShip
		
func GetShipSaveData() -> SaveData:
	var dat = SaveData.new()
	dat.DataName = "Ship"
	var Datas : Array[Resource]
	Datas.append(CurrentShip)
	dat.Datas = Datas
	return dat
	
func LoadData(Data : Resource) -> void:
	var dat = Data as StatSave
	ShipDat.SetStatValue("HP", dat.Value[0])
	ShipDat.SetStatValue("HULL", dat.Value[1])
	ShipDat.SetStatValue("OXYGEN", dat.Value[2])
	ShipDat.SetStatValue("FUEL", dat.Value[3])
	
func GetInventory() -> Inventory:
	return $Ingame_UIManager/Inventory
	
func GetMap() -> Map:
	return $Map

func GetStatPanel() -> StatPanel:
	return $Ingame_UIManager/Stat_Panel

func TestTrade() -> void:
	StartShipTrade(load("res://Resources/Ships/Ship2.tres") as BaseShip)
	
func OnItemAdded(It : Item) -> void:
	if (It is ShipPart and !It.IsDamaged):
		ShipDat.ApplyShipPartStat(It)
		ItemBuffStat(It.UpgradeName)
func OnItemRemoved(It : Item) -> void:
	if (It is ShipPart and !It.IsDamaged):
		ShipDat.RemoveShipPartStat(It)
		ItemBuffStat(It.UpgradeName)
func OnItemRepaired(Part : ShipPart) -> void:
	ShipDat.ApplyShipPartStat(Part)
	ItemBuffStat(Part.UpgradeName)
func OnItemDamaged(Part : ShipPart) -> void:
	ShipDat.RemoveShipPartStat(Part)
	ItemBuffStat(Part.UpgradeName)
func ItemBuffStat(UpName : String) -> void:
	if (UpName == "VIZ_RANGE"):
		$Map.player_ship.UpdateVizRange(ShipDat.GetStat("VIZ_RANGE").GetStat())
	else :if (UpName == "ANALYZE_RANGE"):
		$Map.player_ship.UpdateAnalyzerRange(ShipDat.GetStat("ANALYZE_RANGE").GetStat())
	else :if (UpName == "FUEL_EFFICIENCY" or UpName == "FUEL"):
		$Map.player_ship.UpdateFuelRange(ShipDat.GetStat("FUEL").GetCurrentValue(), ShipDat.GetStat("FUEL_EFFICIENCY").GetStat())
		
func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("Pause")):
		Pause()
		
func Pause() -> void:
	var paused = get_tree().paused
	get_tree().paused = !paused
	$CanvasLayer2/PauseContainer.visible = !paused
	
func StartFight(PossibleReward : Array[Item]) -> void:
	var BScene = BattleScene.instantiate() as Battle
	BScene.SupplyReward = PossibleReward
	BScene.PlayerHp = ShipDat.HP
	$Ingame_UIManager.add_child(BScene)
	BScene.connect("OnBattleEnded", FightEnded)
	
func FightEnded(Resault : bool, RemainingHP : int, SupplyRew : Array[Item]) -> void:
	ShipDat.HP = RemainingHP
	if (Resault):
		GetInventory().AddItems(SupplyRew)
		ShipDat.SetStatValue("HP", RemainingHP)
	else :
		GameLost("You have died")
		
func StartExploration(Spot : MapSpot) -> void:
	var Escene = ExplorationScene.instantiate() as Exploration
	if (Spot.SpotType.HasAtmoshere):
		ShipData.GetInstance().SetStatValue("OXYGEN", ShipData.GetInstance().GetStat("OXYGEN").GetStat())
		PopUpManager.GetInstance().DoPopUp("You oxygen tanks have been refilled when entering the atmopshere")
	Escene.PlayerHp = ShipDat.GetStat("HP").CurrentVelue
	Escene.PlayerOxy = ShipDat.GetStat("OXYGEN").CurrentVelue
	Ingame_UIManager.GetInstance().add_child(Escene)
	Escene.StartExploration(Spot.SpotType, CurrentShip)
	Escene.connect("OnExplorationEnded", ExplorationEnded)
	
func ExplorationEnded(RemainingHP : int, RemainingOxy : int, SupplyRew : Array[Item]) -> void:
	ShipDat.SetStatValue("HP", RemainingHP)
	ShipDat.SetStatValue("OXYGEN", RemainingOxy)
	GetInventory().AddItems(SupplyRew)
	
func StartStage(Size : int) -> void:
	var sc = TraveMinigameScene.instantiate() as TravelMinigameGame
	sc.EnemyGoal = Size
	sc.CharacterScene = CurrentShip.ShipScene
	sc.Hull = ShipDat.GetStat("HULL").GetCurrentValue()
	sc.HullMax = ShipDat.GetStat("HULL").GetStat()
	sc.connect("OnGameEnded", StageDone)
	$Ingame_UIManager.add_child(sc)
	var map = GetMap()
	map.ToggleVis(false)
	$Ingame_UIManager.visible = false
	map.set_process(false)
	map.set_process_input(false)

func StageDone(victory : bool, supplies : Array[Item], HullHP : int) -> void:
	if (victory):
		GetInventory().AddItems(supplies)
	else :
		GetMap().StageFailed()
		GameLost("Your ship got destroyed")
		return
	ShipDat.SetStatValue("HULL", HullHP)
	var map = GetMap()
	map.set_process(true)
	map.set_process_input(true)
	map.ToggleVis(true)
	$Ingame_UIManager.visible = true
#/////////////////////////////////////////////////////////////////////////////////////

func ShipSearched(Ship : BaseShip):
	StartShipTrade(Ship)
	
func StageSearch(Spt : MapSpot)-> void:
	if (Spt.SpotType.CanLand):
		StartExploration(Spt)
	else:
		if (ShipDat.GetStat("OXYGEN").GetCurrentValue() <= 5):
			PopUpManager.GetInstance().DoPopUp("Not enough oxygen to complete action")
			return
		if (ShipDat.GetStat("HP").GetCurrentValue() <= 10):
			PopUpManager.GetInstance().DoPopUp("Not enough HP to complete action")
			return
		GetInventory().AddItems(Spt.SpotType.GetSpotDrop())
		ShipDat.ConsumeResource("HP", 10)
		ShipDat.ConsumeResource("OXYGEN", 5)

func UseItem(It : UsableItem) -> bool:
	var statname = It.StatUseName
	if (ShipDat.GetStat(statname).GetCurrentValue() == ShipDat.GetStat(statname).GetStat()):
		PopUpManager.GetInstance().DoPopUp(statname + " is already full")
		return false
	else :
		ShipDat.RefilResource(statname, 20)
		ItemBuffStat(statname)
		return true
	
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
	OnGameEnded.emit()

func _on_pause_pressed() -> void:
	Pause()

func _on_return_pressed() -> void:
	Pause()

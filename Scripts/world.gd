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

var Loading = false

func _ready() -> void:
	var map = GetMap()
	map.connect("AsteroidBeltArrival", StartStage)
	map.connect("StageSearched", StageSearch)
	map.connect("ShipSearched", ShipSearched)
	UISoundMan.GetInstance().Refresh()
	if (!Loading):
		PlayIntro()
	#call_deferred("TestTrade")

func PlayIntro():
	GetMap().PlayIntroFadeInt()
	var DiagText : Array[String] = ["Operator.....", "Are you awake ?...", "We've drifted away, i am not sure where we are.", "Let me run a background check on the ship's systems...", "... ... ... ...", "Cockpit controlls are offline..", "Monitoring controlls are offline...", "Restarting mainframe..."]
	Ingame_UIManager.GetInstance().CallbackDiag(DiagText, ShowStation, true)
	$Ingame_UIManager/VBoxContainer/HBoxContainer/InventoryButton.visible = false
	$Ingame_UIManager/VBoxContainer/HBoxContainer/Stat_Panel.visible = false
	GetMap().ToggleUIForIntro(false)
func ShowStation():
	var DiagText : Array[String]  = ["Operator, I have found the station.", "Setting course for station, lets head back.", "I am also seeing other stations on our way there, i've marked them on your map.", "I dont know if they are friendly but we have no choice. We will need to stop and refuel"]
	Ingame_UIManager.GetInstance().CallbackDiag(DiagText, ReturnCamToPlayer, true)
	GetMap().ShowStation()
func ReturnCamToPlayer():
	#var DiagText = []
	#Ingame_UIManager.GetInstance().CallbackDiag(DiagText, EnableBackUI)
	EnableBackUI()
	GetMap().FrameCamToPlayer()
func EnableBackUI():
	$Ingame_UIManager/VBoxContainer/HBoxContainer/InventoryButton.visible = true
	$Ingame_UIManager/VBoxContainer/HBoxContainer/Stat_Panel.visible = true
	GetMap().ToggleUIForIntro(true)
func _enter_tree() -> void:
	connect("StatsUpdated", $Ingame_UIManager/VBoxContainer/HBoxContainer/Stat_Panel.StatsUp)
	connect("StatGotLow", $Ingame_UIManager/VBoxContainer/HBoxContainer/Stat_Panel.StatsLow)
	
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
		if (!StatsNotifiedLow.has(StatName) and !GetMap().GetPlayerShip().ShowingNotif()):
			StatsNotifiedLow.append(StatName)
			GetMap().GetPlayerShip().OnStatLow(StatName)
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
	return $Ingame_UIManager/VBoxContainer/Inventory
	
func GetDialogueProgress() -> DialogueProgressHolder:
	return 	$DialogueProgressHolder
	
func GetMap() -> Map:
	return $Map

func GetStatPanel() -> StatPanel:
	return $Ingame_UIManager/VBoxContainer/HBoxContainer/Stat_Panel

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
func OnItemUsed(It : UsableItem) -> void:
	ShipDat.RefilResource(It.StatUseName, 20)
	ItemBuffStat(It.StatUseName)
	
func ItemBuffStat(UpName : String) -> void:
	if (UpName == "VIZ_RANGE"):
		GetMap().GetPlayerShip().UpdateVizRange(ShipDat.GetStat("VIZ_RANGE").GetStat())
	else :if (UpName == "ANALYZE_RANGE"):
		GetMap().GetPlayerShip().UpdateAnalyzerRange(ShipDat.GetStat("ANALYZE_RANGE").GetStat())
	else :if (UpName == "FUEL_EFFICIENCY" or UpName == "FUEL"):
		GetMap().GetPlayerShip().UpdateFuelRange(ShipDat.GetStat("FUEL").GetCurrentValue(), ShipDat.GetStat("FUEL_EFFICIENCY").GetStat())
		
func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("Pause")):
		Pause()
		
func Pause() -> void:
	var paused = get_tree().paused
	get_tree().paused = !paused
	$Ingame_UIManager/PauseContainer.visible = !paused
	
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
	#Escene.PlayerHp = ShipDat.GetStat("HP").CurrentVelue
	#Escene.PlayerOxy = ShipDat.GetStat("OXYGEN").CurrentVelue
	Ingame_UIManager.GetInstance().AddUI(Escene)
	Escene.StartExploration(Spot.SpotType, CurrentShip)
	Escene.connect("OnExplorationEnded", ExplorationEnded)
	GetInventory().ForceCloseInv()
func ExplorationEnded(SupplyRew : Array[Item]) -> void:
	GetInventory().AddItems(SupplyRew)
	
func StartStage(Size : int) -> void:
	
	var sc = TraveMinigameScene.instantiate() as TravelMinigameGame
	sc.EnemyGoal = Size
	sc.CharacterScene = CurrentShip.ShipScene
	#sc.Hull = ShipDat.GetStat("HULL").GetCurrentValue()
	#sc.HullMax = ShipDat.GetStat("HULL").GetStat()
	sc.connect("OnGameEnded", StageDone)
	$Ingame_UIManager.AddUI(sc)
	GetInventory().ForceCloseInv()
	$Ingame_UIManager.ToggleInventoryButton(false)
	var map = GetMap()
	map.ToggleVis(false)
	#$Ingame_UIManager.visible = false
	map.set_process(false)
	map.set_process_input(false)

func StageDone(victory : bool, supplies : Array[Item]) -> void:
	if (victory):
		GetInventory().AddItems(supplies)
	else :
		GetMap().StageFailed()
		GameLost("Your ship got destroyed")
		return
	var map = GetMap()
	map.set_process(true)
	map.set_process_input(true)
	map.ToggleVis(true)
	$Ingame_UIManager.ToggleInventoryButton(true)
	#$Ingame_UIManager.visible = true
#/////////////////////////////////////////////////////////////////////////////////////

func ShipSearched(Ship : BaseShip):
	StartShipTrade(Ship)



func StageSearch(Spt : MapSpot)-> void:
	if (Spt.SpotType.CanLand):
		StartExploration(Spt)
	else:
		if (Spt.SpotType.HasAtmoshere):
			if (ShipData.GetInstance().GetStat("OXYGEN").GetCurrentValue() < ShipData.GetInstance().GetStat("OXYGEN").GetStat()):
				ShipData.GetInstance().SetStatValue("OXYGEN", ShipData.GetInstance().GetStat("OXYGEN").GetStat())
				PopUpManager.GetInstance().DoPopUp("You oxygen tanks have been refilled when entering the atmopshere")
		else:
			if (ShipDat.GetStat("OXYGEN").GetCurrentValue() <= 5):
				PopUpManager.GetInstance().DoPopUp("Not enough oxygen to complete action")
				return
			ShipDat.ConsumeResource("OXYGEN", 5)
		if (ShipDat.GetStat("HP").GetCurrentValue() <= 10):
			PopUpManager.GetInstance().DoPopUp("Not enough HP to complete action")
			return
			
		
		GetInventory().AddItems(Spt.SpotType.GetSpotDrop())
		ShipDat.ConsumeResource("HP", 10)
		
func GameLost(reason : String):
	get_tree().paused = true
	$Ingame_UIManager/PanelContainer.visible = true
	$Ingame_UIManager/PanelContainer/VBoxContainer/Label.text = reason

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

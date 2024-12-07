extends Control
class_name World

@export var ShipDat : ShipData

@export var TraveMinigameScene :PackedScene
@export var BattleScene : PackedScene
@export var ExplorationScene : PackedScene
@export var StartingShip : BaseShip
@export var ShipTradeScene : PackedScene
@export var DogfightScene : PackedScene

#ship player is currently using
var CurrentShip : BaseShip
# array holding the strings of the stats that we have already notified the player that are getting low
var StatsNotifiedLow : Array[String] = []

signal WRLD_OnGameEnded()
signal WRLD_StatsUpdated(StatN : String)
signal WRLD_StatGotLow(StatN : String)

var Loading = false

static var Instance : World
static func GetInstance() -> World:
	return Instance
func _ready() -> void:
	UISoundMan.GetInstance().Refresh()
	Instance = self
	if (!Loading):
		PlayIntro()
	#call_deferred("TestTrade")

func PlayIntro():
	GetMap().PlayIntroFadeInt()
	var DiagText : Array[String] = ["Operator.....", "Are you awake ?...", "We've almost arrived ar Cardi. We are slowly entering enemy territory, i advise caution.", "Our journey is comming to an end slowly...", "I recomend staying out of the cities, there are heave patrols checking the roads to and from each city."]
	Ingame_UIManager.GetInstance().CallbackDiag(DiagText, ShowStation, true)
	$Ingame_UIManager/VBoxContainer/HBoxContainer/Panel.visible = false
	$Ingame_UIManager/VBoxContainer/HBoxContainer/Stat_Panel.visible = false
	GetMap().ToggleUIForIntro(false)
func ShowStation():
	var DiagText : Array[String]  = ["Dormak is a few killometers away.", "Lets be cautious and slowly make our way there.", "Multiple cities exist on the way there but i'd advise against visiting unless on great need.", "Most of the cities in this are are inhabited by enemy troops, even if we dont stumble on a patrol, occupants of the cities might report our location to the enemy."]
	Ingame_UIManager.GetInstance().CallbackDiag(DiagText, ReturnCamToPlayer, true)
	GetMap().ShowStation()
func ReturnCamToPlayer():
	#var DiagText = []
	#Ingame_UIManager.GetInstance().CallbackDiag(DiagText, EnableBackUI)
	EnableBackUI()
	GetMap().FrameCamToPlayer()
func EnableBackUI():
	$Ingame_UIManager/VBoxContainer/HBoxContainer/Panel.visible = true
	$Ingame_UIManager/VBoxContainer/HBoxContainer/Stat_Panel.visible = true
	GetMap().ToggleUIForIntro(true)
func _enter_tree() -> void:
	var map = GetMap()
	#map.connect("MAP_AsteroidBeltArrival", StartStage)
	map.connect("MAP_EnemyArrival", StartDogFight)
	map.connect("MAP_StageSearched", StageSearch)
	map.connect("MAP_ShipSearched", ShipSearched)
	
	var inventory = GetInventory()
	inventory.connect("INV_OnItemAdded", OnItemAdded)
	inventory.connect("INV_OnItemRemoved", OnItemRemoved)
	inventory.connect("INV_OnItemUsed", OnItemUsed)
	inventory.connect("INV_OnShipPartDamaged", OnItemDamaged)
	inventory.connect("INV_OnShipPartFixed", OnItemRepaired)
	
	var statp = GetStatPanel()
	connect("WRLD_StatsUpdated", statp.StatsUp)
	connect("WRLD_StatGotLow", statp.StatsLow)
	
	ShipDat.connect("SD_StatsUpdated", OnStatsUpdated)
	
	GetInventory().UpdateShipInfo(StartingShip)
	ShipDat.ApplyShipStats(StartingShip.Buffs)
	
	GetMap().GetPlayerShip().SetShipType(StartingShip)
	CurrentShip = StartingShip
	ShipDat._UpdateStatCurrentValue("HP", ShipDat.GetStat("HP").GetStat())
	
func _exit_tree() -> void:
	ShipDat.RemoveShipStats(CurrentShip.Buffs)
	GetMap().GetPlayerShip().GetDroneDock().ClearAllDrones()
func OnStatsUpdated(StatName : String):
	#if (ShipDat.GetStat(StatName).GetCurrentValue() < ShipDat.GetStat(StatName).GetStat() - 20):
		#var it = GetInventory().GetItemForStat(StatName)
		#if (GetStatPanel().StatAutoRefil(StatName) and it != null):
			#GetInventory().UseItem(it)
	if (ShipDat.GetStat(StatName).GetCurrentValue() < ShipDat.GetStat(StatName).GetStat() * 0.2):
		if (!StatsNotifiedLow.has(StatName) and !GetMap().GetPlayerShip().ShowingNotif()):
			StatsNotifiedLow.append(StatName)
			GetMap().GetPlayerShip().OnStatLow(StatName)
			WRLD_StatGotLow.emit(StatName)
	else:
		if (StatsNotifiedLow.has(StatName)):
			StatsNotifiedLow.remove_at(StatsNotifiedLow.find(StatName))
	WRLD_StatsUpdated.emit(StatName)
	ItemBuffStat(StatName)
	
func StartShipTrade(NewShip : BaseShip) -> void:
	SimulationManager.GetInstance().TogglePause(true)
	var tradesc = ShipTradeScene.instantiate() as ShipTrade
	$Ingame_UIManager.add_child(tradesc)
	tradesc.StartTrade(CurrentShip, NewShip)
	tradesc.connect("OnTradeFinished", ChangeShip)
	
func ChangeShip(NewShip : BaseShip) -> void:
	SimulationManager.GetInstance().TogglePause(false)
	if (NewShip == CurrentShip):
		return
	GetInventory().UpdateShipInfo(NewShip)
	ShipDat.RemoveShipStats(CurrentShip.Buffs)
	ShipDat.ApplyShipStats(NewShip.Buffs)
	GetInventory().UpdateSize()
	GetMap().GetPlayerShip().SetShipType(NewShip)
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
	#ShipDat.SetStatValue("OXYGEN", dat.Value[2])
	ShipDat.SetStatValue("FUEL", dat.Value[2])
	ItemBuffStat("FUEL")
	
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
		
#Dogfight-----------------------------------------------
var FighingFriendlyUnits : Array[Node2D]
var FighingEnemyUnits : Array[Node2D]
func StartDogFight(Friendlies : Array[Node2D], Enemies : Array[Node2D]):
	FighingFriendlyUnits = Friendlies
	FighingEnemyUnits = Enemies
	
	var FBattleStats : Array[BattleShipStats] = []
	for g in Friendlies:
		FBattleStats.append(g.GetBattleStats())
	var EBattleStats : Array[BattleShipStats] = []
	for g in Enemies:
		EBattleStats.append(g.GetBattleStats())
	var Dscene = DogfightScene.instantiate() as BattleArena
	Dscene.connect("OnBattleEnded", DogFightEnded)
	SimulationManager.GetInstance().TogglePause(true)
	Dscene.SetBattleData(FBattleStats, EBattleStats)
	Ingame_UIManager.GetInstance().AddUI(Dscene, false, true)
func DogFightEnded(Survivors : Array[BattleShipStats]) -> void:
	
	for g in Survivors:
		var nam = g.Name
		for z in FighingFriendlyUnits:
			if z is PlayerShip and nam == "Player":
				ShipData.GetInstance().SetStatValue("HULL", g.Hull)
				FighingFriendlyUnits.erase(z)
				break
			if z is Drone and nam == z.Cpt.CaptainName:
				FighingFriendlyUnits.erase(z)
				break
	for g in FighingFriendlyUnits:
		if (g is PlayerShip):
			GetMap().StageFailed()
			GameLost("Your ship got destroyed")
			return
		if (g is Drone):
			CaptainUI.GetInstance().OnCaptainDischarged(g.Cpt)
	for g in FighingEnemyUnits:
		MapPointerManager.GetInstance().RemoveShip(g)
		g.free()
	SimulationManager.GetInstance().TogglePause(false)
#Exploration---------------------------------------------
func StartExploration(Spot : MapSpot) -> void:
	var Escene = ExplorationScene.instantiate() as Exploration
	#if (Spot.SpotType.HasAtmoshere):
		#ShipDat.SetStatValue("OXYGEN", ShipData.GetInstance().GetStat("OXYGEN").GetStat())
		#PopUpManager.GetInstance().DoPopUp("You oxygen tanks have been refilled when entering the atmopshere")
	#Escene.PlayerHp = ShipDat.GetStat("HP").CurrentVelue
	#Escene.PlayerOxy = ShipDat.GetStat("OXYGEN").CurrentVelue
	Ingame_UIManager.GetInstance().AddUI(Escene)
	Escene.StartExploration(Spot.SpotType, CurrentShip)
	Escene.connect("OnExplorationEnded", ExplorationEnded)
	GetInventory().ForceCloseInv()
	
func ExplorationEnded(SupplyRew : Array[Item]) -> void:
	GetInventory().AddItems(SupplyRew)
#--------------------------------------------------------
func StartStage(Size : int) -> void:
	#spawn scene
	var sc = TraveMinigameScene.instantiate() as TravelMinigameGame
	#set leangth of stage
	sc.EnemyGoal = Size
	#set player ship
	sc.CharacterScene = CurrentShip.ShipScene
	#set stage end signal
	sc.connect("OnGameEnded", StageDone)
	#add to hierarchy
	$Ingame_UIManager.AddUI(sc)
	#make sure that inventory is closed
	GetInventory().ForceCloseInv()
	#make sure player wont be able to open inventory durring gameplay
	$Ingame_UIManager.ToggleInventoryButton(false)
	#make sure ships dont keep working on map to avoid any UI poping
	SimulationManager.GetInstance().TogglePause(true)
	#turn off map
	var map = GetMap()
	map.ToggleVis(false)
	map.set_process(false)
	map.set_process_input(false)
# called by signalonce stage is done, returns if player died, and supplies they found
func StageDone(victory : bool, supplies : Array[Item]) -> void:
	#if player died, let them know why and kill game
	if (!victory):
		GetMap().StageFailed()
		GameLost("Your ship got destroyed")
		return
	
	SimulationManager.GetInstance().TogglePause(false)
	#if player didnt die add the supplies he found in the inventory
	GetInventory().AddItems(supplies)
	#enable map again
	var map = GetMap()
	map.set_process(true)
	map.set_process_input(true)
	map.ToggleVis(true)
	#enable ship movement
	
	#enable inventory button
	$Ingame_UIManager.ToggleInventoryButton(true)
#/////////////////////////////////////////////////////////////////////////////////////

func ShipSearched(Ship : BaseShip):
	StartShipTrade(Ship)

func StageSearch(Spt : MapSpot)-> void:
	if (Spt.SpotType.CanLand):
		StartExploration(Spt)
	else:
		#if (Spt.SpotType.HasAtmoshere):
			#if (ShipData.GetInstance().GetStat("OXYGEN").GetCurrentValue() < ShipData.GetInstance().GetStat("OXYGEN").GetStat()):
				#ShipData.GetInstance().SetStatValue("OXYGEN", ShipData.GetInstance().GetStat("OXYGEN").GetStat())
				#PopUpManager.GetInstance().DoPopUp("You oxygen tanks have been refilled when entering the atmopshere")
		#else:
			#if (ShipDat.GetStat("OXYGEN").GetCurrentValue() <= 5):
				#PopUpManager.GetInstance().DoPopUp("Not enough oxygen to complete action")
				#return
			#ShipDat.ConsumeResource("OXYGEN", 5)
		if (ShipDat.GetStat("HP").GetCurrentValue() <= 10):
			PopUpManager.GetInstance().DoPopUp("Not enough HP to complete action")
			return
		GetInventory().AddItems(Spt.SpotType.GetSpotDrop())
		ShipDat.ConsumeResource("HP", 10)
		
func GameLost(reason : String):
	get_tree().paused = true
	$Ingame_UIManager/PanelContainer.visible = true
	$Ingame_UIManager/PanelContainer/VBoxContainer/Label.text = reason

func _on_save_pressed() -> void:
	SaveLoadManager.GetInstance().Save(self)
	PopUpManager.GetInstance().DoFadeNotif("Save successful")
	
func _on_exit_pressed() -> void:
	WRLD_OnGameEnded.emit()

func _on_pause_pressed() -> void:
	Pause()

func _on_return_pressed() -> void:
	Pause()

func On_Game_Lost_Button_Pressed() -> void:
	WRLD_OnGameEnded.emit()

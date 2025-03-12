extends Control
class_name World

@export_group("Nodes")
@export var _Map : Map
@export var _Command : Commander
@export var Controller : ShipContoller
@export_group("Scenes")
@export var CardFightScene : PackedScene
@export var LoadingScene : PackedScene
@export var FleetSeparationScene : PackedScene
@export_group("Wallet")
@export var StartingFunds : int = 500000
@export var PlayerWallet : Wallet

# array holding the strings of the stats that we have already notified the player that are getting low
var StatsNotifiedLow : Array[String] = []

signal WRLD_OnGameEnded
signal WRLD_WorldReady
#signal WRLD_StatsUpdated(StatN : String)
signal WRLD_StatGotLow(StatN : String)

var Loading = false

static var Instance : World

static func GetInstance() -> World:
	return Instance

func _ready() -> void:
	#$Inventory.Player = GetMap().GetPlayerShip()
	var Loadingscr = LoadingScene.instantiate() as LoadingScreen
	add_child(Loadingscr)
	#TODO needs fix
	if (!Loading):
		Loadingscr.ProcessStarted("Generating Map Spot Plecement")
		GetMap().GenerateMap()
		await GetMap().GenerationFinished
		Loadingscr.ProcesFinished("Generating Map Spot Plecement")
		Loadingscr.UpdateProgress(10)
		Loadingscr.ProcessStarted("Generating Events")
		GetMap().GenerateEvents()
		await GetMap().GenerationFinished
		Loadingscr.ProcesFinished("Generating Events")
	Loadingscr.UpdateProgress(20)
	Loadingscr.ProcessStarted("Generating Road Networks")
	GetMap().GenerateRoads()
	await GetMap().GenerationFinished
	Loadingscr.ProcesFinished("Generating Road Networks")
	Loadingscr.ProcessStarted("Generating Spot Connections")
	Loadingscr.UpdateProgress(40)
	await GetMap().GenerationFinished
	Loadingscr.ProcesFinished("Generating Spot Connections")
	Loadingscr.UpdateProgress(60)
	if (!Loading):
		Loadingscr.ProcessStarted("Spawning Enemy Fleets")
		GetMap().SpawnTownEnemies()
		await GetMap().GenerationFinished
		Loadingscr.ProcesFinished("Creating Enemy Fleets")
		Loadingscr.ProcessStarted("Placing Fleets In World")
		Loadingscr.UpdateProgress(80)
		await GetMap().GenerationFinished
		Loadingscr.ProcesFinished("Placing Fleets In World")
	Loadingscr.UpdateProgress(100)
	Loadingscr.StartDest()
	GetMap()._InitialPlayerPlacament()
	$ShipController.SetInitialShip()
	UISoundMan.GetInstance().Refresh()
	Instance = self
	WRLD_WorldReady.emit()
	if (!Loading):
		await Loadingscr.LoadingDestroyed
		PlayIntro()
		PlayerWallet.SetFunds( StartingFunds)
	
	
func GetSaveData() -> SaveData:
	var Data = SaveData.new()
	Data.DataName = "Wallet"
	Data.Datas.append(PlayerWallet)
	return Data

func LoadSaveData(PlWallet : Wallet) -> void:
	PlayerWallet.SetFunds(PlWallet.Funds)

func PlayIntro():
	#GetMap().PlayIntroFadeInt()
	var DiagText : Array[String] = ["Operator.....", "Are you awake ?...", "We've almost arrived ar Cardi. We are slowly entering enemy territory, i advise caution.", "Our journey is comming to an end slowly...", "I recomend staying out of the cities, there are heave patrols checking the roads to and from each city."]
	Ingame_UIManager.GetInstance().CallbackDiag(DiagText, load("res://Assets/artificial-hive.png"), ShowStation, true)
	#$Ingame_UIManager/VBoxContainer/HBoxContainer/Panel.visible = false
	#$Ingame_UIManager/VBoxContainer/HBoxContainer/Stat_Panel.visible = false
	#GetMap().ToggleUIForIntro(false)

func ShowStation():
	var DiagText : Array[String]  = ["Dormak is a few killometers away.", "Lets be cautious and slowly make our way there.", "Multiple cities exist on the way there but i'd advise against visiting unless on great need.", "Most of the cities in this are are inhabited by enemy troops, even if we dont stumble on a patrol, occupants of the cities might report our location to the enemy."]
	Ingame_UIManager.GetInstance().CallbackDiag(DiagText, load("res://Assets/artificial-hive.png"), ReturnCamToPlayer, true)
	GetMap().GetCamera().ShowStation()

func ReturnCamToPlayer():
	EnableBackUI()
	GetMap().GetCamera().FrameCamToPlayer()

func EnableBackUI():
	#$Ingame_UIManager/VBoxContainer/HBoxContainer/Panel.visible = true
	#$Ingame_UIManager/VBoxContainer/HBoxContainer/Stat_Panel.visible = true
	#Ingame_UIManager.GetInstance().ToggleScreenUI(true)
	GetMap().GetScreenUi().ToggleScreenUI(true)

func _enter_tree() -> void:
	var map = GetMap()
	
	map.connect("MAP_EnemyArrival", StartDogFight)
	Controller.connect("FleetSeperationRequested", StartShipTrade)
	#var statp = GetStatPanel()
	##connect("WRLD_StatsUpdated", statp.StatsUp)
	#connect("WRLD_StatGotLow", statp.StatsLow)
	
	#GetMap().GetPlayerShip().SetShipType(StartingShip)
	#CurrentShip = StartingShip

func TerminateWorld() -> void:
	#GetMap().GetInScreenUI().GetInventory().FlushInventory()
	var PlShip = get_tree().get_nodes_in_group("Ships")[0]
	if (PlShip is PlayerShip):
		InventoryManager.GetInstance().OnCharacterRemoved(PlShip.Cpt)
		PlShip.GetDroneDock().ClearAllDrones()

func GetDialogueProgress() -> DialogueProgressHolder:
	return $DialogueProgressHolder

func GetMap() -> Map:
	return _Map
func GetCommander() -> Commander:
	return _Command
#func GetStatPanel() -> StatPanel:
	#return GetMap()._StatPanel

#ShipTrade
func StartShipTrade(ControlledShip : MapShip) -> void:
	SimulationManager.GetInstance().TogglePause(true)
	var CurrentFleet : Array[MapShip] = [ControlledShip]
	for S in ControlledShip.GetDroneDock().DockedDrones:
		CurrentFleet.append(S)
	
	if (CurrentFleet.size() == 1):
		PopUpManager.GetInstance().DoFadeNotif("Cant separate current fleet")
		return
	var sc = FleetSeparationScene.instantiate() as FleetSeparation
	sc.CurrentFleet = CurrentFleet
	Ingame_UIManager.GetInstance().AddUI(sc)
	GetMap().GetScreenUi().ToggleFullScreen(true)
	sc.connect("SeperationFinished", ShipSeparationFinished)
		
func ShipSeparationFinished() -> void:
	GetMap().GetScreenUi().ToggleFullScreen(false)
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
	var CardF = CardFightScene.instantiate() as Card_Fight
	CardF.connect("CardFightEnded", CardFightEnded)
	CardF.PlayerShips = FBattleStats
	CardF.EnemyShips = EBattleStats
	SimulationManager.GetInstance().TogglePause(true)
	#CardF.SetBattleData(FBattleStats, EBattleStats)
	Ingame_UIManager.GetInstance().AddUI(CardF, true, false)
	GetMap().GetScreenUi().ToggleControllCover(true)
	GetMap().GetScreenUi().ToggleFullScreen(true)
	UISoundMan.GetInstance().Refresh()
	
func CardFightEnded(Survivors : Array[BattleShipStats]) -> void:
	var AllUnits : Array[MapShip]
	AllUnits.append_array(FighingFriendlyUnits)
	AllUnits.append_array(FighingEnemyUnits)
	var WonFunds = 0
	for Unit in AllUnits:
		var Survived = false
		for Surv in Survivors:
			var Nam = Surv.Name
			if (Unit.GetShipName() == Nam):
				Unit.Damage(Unit.Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL) - Surv.Hull, false)
				if (Unit is not HostileShip):
					FigureOutInventory(Unit.Cpt.GetCharacterInventory(), Surv.Cards, Surv.Ammo)
				else: if (Unit.IsDead()):
					Unit.DestroyEnemyDebry()
					
				Survived = true
				break
		if (!Survived):
			Unit.Damage(99999999999)
			if (Unit is HostileShip):
				Unit.DestroyEnemyDebry()
				WonFunds += Unit.Cpt.ProvidingFunds
	if (WonFunds > 0):
		PlayerWallet.AddFunds(WonFunds)
		PopUpManager.GetInstance().DoFadeNotif("{0} drahma added".format([WonFunds]))
	FighingEnemyUnits.clear()
	FighingFriendlyUnits.clear()
	
	GetMap().GetScreenUi().ToggleControllCover(false)
	GetMap().GetScreenUi().ToggleFullScreen(false)

#Make sure to remove all items that their cards have been used
func FigureOutInventory(CharInv : CharacterInventory, Cards : Dictionary, Ammo : Dictionary):
	#get inventory contents, make sure to duplicate so that removing elements doesent fuck with this
	var Contents = CharInv.GetInventoryContents().duplicate()
	for It in Contents.keys():
		var Itm = It as Item
		for g in Contents[It]:
			#if item doesent provide a card then it def didnt get used
			if (Itm.CardProviding.size() > 0):
				for c in Itm.CardProviding:
				#if it did remove it from dictionary and leave ininside inventory
					if (Cards.has(c)):
						Cards[c] -= 1
						if (Cards[c] == 0):
							Cards.erase(c)
				#if it was used and we cant find it in the dictionary then remove it from inventory
					else:
						CharInv.RemoveItem(Itm)
			
			if (Itm.CardOptionProviding != null):
				#if it did remove it from dictionary and leave ininside inventory
				if (Ammo.has(Itm.CardOptionProviding)):
					Ammo[Itm.CardOptionProviding] -= 1
					if (Ammo[Itm.CardOptionProviding] == 0):
						Ammo.erase(Itm.CardOptionProviding)
				#if it was used and we cant find it in the dictionary then remove it from inventory
				else:
					CharInv.RemoveItem(Itm)
#--------------------------------------------------------
func GameLost(reason : String):
	get_tree().paused = true
	$Map/SubViewportContainer/ViewPort/InScreenUI/Control3/PanelContainer.visible = true
	$Map/SubViewportContainer/ViewPort/InScreenUI/Control3/PanelContainer/VBoxContainer/Label.text = reason

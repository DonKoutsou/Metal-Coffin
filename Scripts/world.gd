extends Control
class_name World

@export_group("Nodes")
@export var _Map : Map
@export var _Command : Commander
@export var Controller : ShipContoller
@export_group("Scenes")
@export var CardFightScene : String
@export var LoadingScene : String
@export var FleetSeparationScene : String
@export var HappeningUI : String
@export var WorldViewQuestionairScene : String
@export var IntroText : String
@export_group("Prologue")
@export var PrologueTrigger : PackedScene
@export var PrologueEndScreen : PackedScene
@export_group("Wallet")
@export var StartingFunds : int = 500000
@export var PlayerWallet : Wallet
@export_group("Settings")
@export var IsPrologue : bool = false
@export var StartingFuel : float = 100
@export_group("Dialogues")
@export_multiline var IntroDialogues : Array[String]
@export_multiline var IntroDialogue2 : Array[String]
@export_multiline var PrologueDialgues : Array[String]
@export_multiline var PrologueDialogues2 : Array[String]

# array holding the strings of the stats that we have already notified the player that are getting low
var StatsNotifiedLow : Array[String] = []
var SkipStory : bool
signal WRLD_OnGameEnded
signal WRLD_WorldReady
signal WorldSpawnTransitionFinished
#signal WRLD_StatsUpdated(StatN : String)
signal WRLD_StatGotLow(StatN : String)

var OverworldEventsToShow : Array[OverworldEventData]
var TutorialsToShow : Array[ActionTracker.Action]

var Loading = false

static var Instance : World

static func GetInstance() -> World:
	return Instance

func _ready() -> void:
	Instance = self
	GetMap().GetScreenUi().DoIntroFullScreen(ScreenUI.ScreenState.FULL_SCREEN)
	await GetMap().GetScreenUi().FullScreenToggleStarted
	WorldSpawnTransitionFinished.emit()
	#$Inventory.Player = GetMap().GetPlayerShip()
	var Loadingscr = load(LoadingScene).instantiate() as LoadingScreen
	Ingame_UIManager.GetInstance().AddUI(Loadingscr, false, false)
	
	#add_child(Loadingscr)
	#TODO needs fix
	if (!Loading):
		Loadingscr.ProcessStarted("Generating Map Spot Plecement")
		GetMap().GenerateMap()
		await GetMap().GenerationFinished
		Loadingscr.ProcesFinished("Generating Map Spot Plecement")
		Loadingscr.UpdateProgress(10)
		await wait(1)
		Loadingscr.ProcessStarted("Generating Events")
		GetMap().GenerateEvents()
		await GetMap().GenerationFinished
		Loadingscr.ProcesFinished("Generating Events")
		await wait(1)
	else:
		Loadingscr.DissableText()
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
	await wait(1)
	if (!Loading):
		Loadingscr.ProcessStarted("Spawning Enemy Fleets")
		GetMap().SpawnTownEnemies()
		await GetMap().GenerationFinished
		Loadingscr.ProcesFinished("Creating Enemy Fleets")
		await wait(1)
		GetMap().EnemySpawnFinished()
		Loadingscr.ProcessStarted("Placing Fleets In World")
		Loadingscr.UpdateProgress(80)
		await GetMap().GenerationFinished
		Loadingscr.ProcesFinished("Placing Fleets In World")
		await wait(1)
	Loadingscr.UpdateProgress(100)
	
	
	
	$ShipController.SetInitialShip()
	UISoundMan.GetInstance().Refresh()
	await wait(1)
	WRLD_WorldReady.emit()
	if (!Loading):
		Loadingscr.StartDest()
		await Loadingscr.IntroFinished
		GetMap()._InitialPlayerPlacament(StartingFuel, IsPrologue)
		GetMap().GetCamera().FrameCamToPlayer()
		if (IsPrologue and !SkipStory):
			GetMap().GetScreenUi().ToggleFullScreen(ScreenUI.ScreenState.FULL_SCREEN)
		else:
			GetMap().GetScreenUi().ToggleFullScreen(ScreenUI.ScreenState.HALF_SCREEN)
		await GetMap().GetScreenUi().FullScreenToggleStarted
		Loadingscr.queue_free()
		
		if (IsPrologue):
			var Trigger = PrologueTrigger.instantiate() as PrologueEnd_Trigger
			var Armak = Helper.GetInstance().GetSpotByName("Armak")
			Armak.add_child(Trigger)
			
			if (!SkipStory):
				var Questionair = load(WorldViewQuestionairScene).instantiate() as WorldViewQuestionair
				Ingame_UIManager.GetInstance().AddUI(Questionair, false, true)
				Questionair.Init()
				await GetMap().GetScreenUi().FullScreenToggleFinished
				#await Loadingscr.LoadingDestroyed
				await Questionair.Ended
				GetMap().GetScreenUi().ToggleFullScreen(ScreenUI.ScreenState.HALF_SCREEN)
				await GetMap().GetScreenUi().FullScreenToggleStarted
				Questionair.queue_free()
				PlayPrologue()
			else:
				var Cardi = Helper.GetInstance().GetSpotByName("Cardi")
				var Pl = get_tree().get_nodes_in_group("PlayerShips")[0] as PlayerShip
				Pl.global_position = Cardi.global_position
				Cardi.Event.SkipStory(Pl)
				Cardi.OnSpotVisited(false)
		else:
			#Load worldview from prologue
			WorldView.GetInstance().Load()
			PlayIntro()
		PlayerWallet.SetFunds( StartingFunds)
	else:
		WorldView.GetInstance().Load()
		
		GetMap().GetScreenUi().ToggleFullScreen(ScreenUI.ScreenState.HALF_SCREEN)
		await GetMap().GetScreenUi().FullScreenToggleStarted
		Loadingscr.queue_free()
		
	
	

func wait(secs : float) -> Signal:
	return get_tree().create_timer(secs).timeout

func GetSaveData() -> SaveData:
	var Data = SaveData.new()
	Data.DataName = "Wallet"
	Data.Datas.append(PlayerWallet.duplicate())
	return Data

func LoadSaveData(PlWallet : Wallet) -> void:
	PlayerWallet.SetFunds(PlWallet.Funds)

func PlayPrologue():
	Ingame_UIManager.GetInstance().CallbackDiag(PrologueDialgues, null, "Seg", SteerTut, true)

func ShowArmak():
	Ingame_UIManager.GetInstance().CallbackDiag(PrologueDialogues2, null, "Seg", ReturnCamToPlayer, true)
	GetMap().GetCamera().ShowArmak()

func SteerTut() -> void:
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.CAMERA_CONTROL)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.CAMERA_CONTROL)
		var text = "Use the [color=#ffc315]WASD[/color] keys or [color=#ffc315]Left Click[/color] and drag the mouse to move the camera. To [color=#ffc315]Zoom In/Out[/color] use the [color=#ffc315]Mouse Wheel[/color]."
		await ActionTracker.GetInstance().ShowTutorial("Camera Controls", text, [], false)
	
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.STEER)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.STEER)
		var text = "Use the [color=#ffc315]Steer[/color] found on the left of the controller to steer the fleet. To controll the speed of the fleet use the [color=#ffc315]Thrust Lever[/color] on the right side of the controller"
		await ActionTracker.GetInstance().ShowTutorial("Controlling the fleet", text, [GetMap().GetScreenUi().Steer, GetMap().GetScreenUi().Thrust.Handle], false)
	

func PlayIntro():
	#GetMap().PlayIntroFadeInt()
	Ingame_UIManager.GetInstance().CallbackDiag(IntroDialogues, load("res://Assets/artificial-hive.png"), "Seg", ShowStation, true)

func ShowStation():
	Ingame_UIManager.GetInstance().CallbackDiag(IntroDialogue2, load("res://Assets/artificial-hive.png"), "Seg", ReturnCamToPlayer, true)
	GetMap().GetCamera().ShowStation()

func ReturnCamToPlayer():
	#EnableBackUI()
	
	GetMap().GetCamera().FrameCamToPlayer()
	
	

func _enter_tree() -> void:
	var map = GetMap()
	
	map.connect("MAP_EnemyArrival", StartDogFight)
	Controller.connect("FleetSeperationRequested", StartShipTrade)
	Controller.connect("LandingRequested", OnLandRequested)
	Controller.OpenHatchRequested.connect(OnOpenHatchRequested)
	#var statp = GetStatPanel()
	##connect("WRLD_StatsUpdated", statp.StatsUp)
	#connect("WRLD_StatGotLow", statp.StatsLow)
	
	#GetMap().GetPlayerShip().SetShipType(StartingShip)
	#CurrentShip = StartingShip

func TerminateWorld() -> void:
	#GetMap().GetInScreenUI().GetInventory().FlushInventory()
	var PlShips = get_tree().get_nodes_in_group("PlayerShips")
	for g : MapShip in PlShips:
		if (g is PlayerShip):
			InventoryManager.GetInstance().OnCharacterRemoved(g.Cpt)
		else:
			g.Kill()
			
func GetDialogueProgress() -> DialogueProgressHolder:
	return $DialogueProgressHolder

func GetMap() -> Map:
	return _Map
func GetCommander() -> Commander:
	return _Command
#func GetStatPanel() -> StatPanel:
	#return GetMap()._StatPanel

#ShipTrade
func StartShipTrade(ControlledShip : PlayerDrivenShip) -> void:
	SimulationManager.GetInstance().TogglePause(true)
	var CurrentFleet : Array[PlayerDrivenShip] = [ControlledShip]
	for S in ControlledShip.GetDroneDock().DockedDrones:
		CurrentFleet.append(S)
	
	if (CurrentFleet.size() == 1):
		PopUpManager.GetInstance().DoFadeNotif("Cant separate current fleet")
		return
	var sc = load(FleetSeparationScene).instantiate() as FleetSeparation
	sc.CurrentFleet = CurrentFleet
	GetMap().GetScreenUi().ToggleScreenUI(false)
	GetMap().GetScreenUi().ShipTradeInProgress = true
	#await GetMap().GetScreenUi().FullScreenToggleStarted
	Ingame_UIManager.GetInstance().AddUI(sc)
	
	sc.connect("SeperationFinished", ShipSeparationFinished)
	await GetMap().GetScreenUi().FullScreenToggleFinished
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.FLEET_SEPARATION)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.FLEET_SEPARATION)
		var text = "In the ship dock screen, you can effectively organize your current fleet. To create a new fleet, simply select the ships you wish to move from your existing fleet.\nDon't forget to allocate fuel appropriately! Use the sliders at the bottom of the screen to ensure each fleet has enough fuel to operate efficiently."
		ActionTracker.GetInstance().ShowTutorial("Ship Dock", text, [], true)
		
func ShipSeparationFinished() -> void:
	#GetMap().GetScreenUi().ToggleFullScreen(ScreenUI.ScreenState.HALF_SCREEN)
	#await GetMap().GetScreenUi().FullScreenToggleStarted
	get_tree().get_nodes_in_group("FleetSep")[0].queue_free()
	GetMap().GetScreenUi().ToggleScreenUI(true)
	GetMap().GetScreenUi().ShipTradeInProgress = false

var InFight : bool = false
#Dogfight-----------------------------------------------
var FighingFriendlyUnits : Array[MapShip] = []
var FighingEnemyUnits : Array[MapShip] = []
func StartDogFight(Friendlies : Array[MapShip], Enemies : Array[MapShip]):
	#Temp solution to stop fight starting twice
	if (InFight):
		return
	####
	InFight = true
	
	var FBattleStats : Array[BattleShipStats] = []
	for g in Friendlies:
		FighingFriendlyUnits.append(g)
		FBattleStats.append(g.GetBattleStats())
	var EBattleStats : Array[BattleShipStats] = []
	for g : HostileShip in Enemies:
		if (g.Destroyed):
			continue
		FighingEnemyUnits.append(g)
		EBattleStats.append(g.GetBattleStats())
	var CardF = load(CardFightScene).instantiate() as Card_Fight
	CardF.connect("CardFightEnded", CardFightEnded)
	CardF.PlayerReserves = FBattleStats
	CardF.EnemyReserves = EBattleStats
	SimulationManager.GetInstance().TogglePause(true)
	#CardF.SetBattleData(FBattleStats, EBattleStats)
	GetMap().GetScreenUi().ToggleFullScreen(ScreenUI.ScreenState.HALF_SCREEN)
	await GetMap().GetScreenUi().FullScreenToggleStarted
	
	GetMap().GetScreenUi().ToggleScreenUI(false)
	GetMap().GetScreenUi().ToggleCardFightUI(true)
	Ingame_UIManager.GetInstance().AddUI(CardF, true, false)
	#GetMap().GetScreenUi().ToggleControllCover(true)
	UISoundMan.GetInstance().Refresh()
	
func CardFightEnded(Survivors : Array[BattleShipStats], _won : bool) -> void:
	var AllUnits : Array[MapShip]
	AllUnits.append_array(FighingFriendlyUnits)
	AllUnits.append_array(FighingEnemyUnits)
	var WonFunds = 0
	for Unit in AllUnits:
		var Survived = false
		for Surv in Survivors:
			var Nam = Surv.Name
			if (Unit.GetShipName() == Nam):
				Unit.Damage(Unit.Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL) - Surv.CurrentHull, false)
				if (Unit is PlayerDrivenShip):
					FigureOutInventory(Unit.Cpt.GetCharacterInventory(), Surv.Cards)
				else: if (Unit.IsDead()):
					Unit.DestroyEnemyDebry()
					
				Survived = true
				break
		if (!Survived):
			Unit.Damage(99999999999, false)
			if (Unit is HostileShip):
				Unit.DestroyEnemyDebry()
				WonFunds += Unit.Cpt.ProvidingFunds
	if (WonFunds > 0):
		PlayerWallet.AddFunds(WonFunds)
		PopUpManager.GetInstance().DoFadeNotif("{0} drahma added".format([WonFunds]))
	FighingEnemyUnits.clear()
	FighingFriendlyUnits.clear()
	
	#GetMap().GetScreenUi().ToggleControllCover(false)
	GetMap().GetScreenUi().ToggleFullScreen(ScreenUI.ScreenState.HALF_SCREEN)
	await GetMap().GetScreenUi().FullScreenToggleStarted
	GetMap().GetScreenUi().ToggleScreenUI(true)
	GetMap().GetScreenUi().ToggleCardFightUI(false)
	get_tree().get_nodes_in_group("CardFight")[0].queue_free()
	InFight = false

#LANDING
func OnLandRequested(ControlledShip : MapShip) -> void:
	var Instigator = ControlledShip
	if (ControlledShip.Docked):
		Instigator = ControlledShip.Command
		
	var spot = Instigator.CurrentPort as MapSpot
	if (spot == null):
		PopUpManager.GetInstance().DoFadeNotif("No port to land to")
		return
	if (Instigator.Landing):
		return
	if (Instigator.Altitude == 0):
		PopUpManager.GetInstance().DoFadeNotif("Fleet already on the ground")
		return
	if (Instigator.GetShipSpeed() > 0):
		PopUpManager.GetInstance().DoFadeNotif("Fleet can't land while moving")
		return
	Instigator.StartLanding()
	RadioSpeaker.GetInstance().PlaySound(RadioSpeaker.RadioSound.LANDING_START)
	PopUpManager.GetInstance().DoFadeNotif("Landing sequence initiated")
	Instigator.connect("LandingEnded", OnLandingFinished)
	Instigator.connect("LandingCanceled", OnLandingCanceled)

func OnOpenHatchRequested(ControlledShip : MapShip) -> void:
	var Instigator = ControlledShip
	if (ControlledShip.Docked):
		Instigator = ControlledShip.Command

	if (Instigator.Altitude > 0):
		PopUpManager.GetInstance().DoFadeNotif("Can't open hatch while ship is floating")
		return
	
	OnShipLanded(Instigator)

func OnLandingCanceled(Ship : MapShip) -> void:
	PopUpManager.GetInstance().DoFadeNotif("Landing sequence canceled")
	Ship.disconnect("LandingEnded", OnLandingFinished)
	Ship.disconnect("LandingCanceled", OnLandingCanceled)

func OnLandingFinished(Ship : MapShip) -> void:
	RadioSpeaker.GetInstance().PlaySound(RadioSpeaker.RadioSound.LANDING_END)
	if (Ship.is_connected("LandingEnded", OnLandingFinished)):
		Ship.disconnect("LandingEnded", OnLandingFinished)
	if (Ship.is_connected("LandingCanceled", OnLandingCanceled)):
		Ship.disconnect("LandingCanceled", OnLandingCanceled)

func OnShipLanded(Ship : MapShip, skiptransition : bool = false) -> void:
	var Inventory = InventoryManager.GetInstance()
	if (Inventory.visible):
		Inventory.ToggleInventory()

	SimulationManager.GetInstance().TogglePause(true)
	var spot = Ship.CurrentPort as MapSpot
	var PlayedEvent = await Land(spot, Ship)
	if (PlayedEvent):
		return
	var sc = spot.FuelTradeScene as PackedScene
	var fuel = sc.instantiate() as TownScene
	#fuel.TownMerch = spot.SpotInfo.Merchendise
	#fuel.HasFuel = spot.HasFuel()
	#fuel.HasRepair = spot.HasRepair()
	#fuel.TownFuel = spot.CityFuelReserves
	fuel.BoughtFuel = spot.PlayerFuelReserves
	fuel.connect("TransactionFinished", FuelTransactionFinished)
	fuel.LandedShips.append_array(spot.VisitingShips)
	fuel.TownSpot = spot
	if (!skiptransition):
		GetMap().GetScreenUi().ToggleFullScreen(ScreenUI.ScreenState.HALF_SCREEN)
		await GetMap().GetScreenUi().FullScreenToggleStarted
		
	Ingame_UIManager.GetInstance().AddUI(fuel, true)
	GetMap().GetScreenUi().ToggleTownUI(true)
	GetMap().GetScreenUi().TownVisited(true)
	await GetMap().GetScreenUi().FullScreenToggleFinished

		
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.TOWN_SHOP)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.TOWN_SHOP)
		var text = "When landing on a town you are able to refuel, repair, rearm and upgrade your fleet.\n\nEach city provides certain bonuses to the price and speed of one or all services. The bonuses can be seen on the left bellow the port's name. Drag on the sliders to buy or sell the shown resource."
		ActionTracker.GetInstance().ShowTutorial("Towns", text, [], true)
	#UIEventH.OnScreenUIToggled(false)
	#UIEventH.OnButtonCoverToggled(true)
func FuelTransactionFinished(BFuel : float, Ships : Array[MapShip], Scene : TownScene):
	var spot = Ships[0].CurrentPort as MapSpot
	if (BFuel < 0):
		var FuelToRemove = BFuel
		for ship : MapShip in Ships:
			var CurrentValue = ship.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
			
			var CurrentFuelToRemove = min(CurrentValue, abs(FuelToRemove))
			
			ship.Cpt.ConsumeResource(STAT_CONST.STATS.FUEL_TANK, CurrentFuelToRemove)
			
			#we add cause fuel to remove should be negative
			FuelToRemove += CurrentFuelToRemove
			
			if (FuelToRemove == 0):
				break

		#if (Ship is PlayerShip):
			#ShipData.GetInstance().ConsumeResource("FUEL", -BFuel)
		#else:
		#Ship.Cpt.RefillResource(STAT_CONST.STATS.FUEL_TANK, BFuel)

	spot.AddToFuelReserves(BFuel)
	
	GetMap().GetScreenUi().ToggleFullScreen(ScreenUI.ScreenState.HALF_SCREEN)
	await GetMap().GetScreenUi().FullScreenToggleStarted
	Scene.queue_free()
	GetMap().GetScreenUi().TownVisited(false)
	GetMap().GetScreenUi().ToggleTownUI(false)
	await GetMap().GetScreenUi().FullScreenToggleFinished
	#Play events saved from happening
	for g in OverworldEventsToShow:
		var Pos = g.GetFocusPos()
		if (Pos != Vector2.ZERO):
			GetMap().GetCamera().FrameCamToPos(Pos, 4.0, true)
			Ingame_UIManager.GetInstance().CallbackDiag(g.Dialogues, null, "", ReturnCamToPlayer, true)
	OverworldEventsToShow.clear()
	
	for g in TutorialsToShow:
		if (g == ActionTracker.Action.RECRUIT and!ActionTracker.IsActionCompleted(ActionTracker.Action.RECRUIT)):
			TutorialsToShow.append(ActionTracker.Action.RECRUIT)
			ActionTracker.OnActionCompleted(ActionTracker.Action.RECRUIT)
			var text = "Managing your fleet is key to a successful campaign.\nShips in the same fleet share [color=#ffc315]Fuel[/color], so adding a ship with extra fuel to a fleet can help it go further.\nTo split and trade fuel between fleets, use the Ship Dock in the controller.\nTo merge [color=#ffc315]Fleets[/color], click the [color=#ffc315]Regroup[/color] button and pick the target fleet.\nSelect a different ship to control by clicking on their name on the right part of the screen."
			ActionTracker.GetInstance().ShowTutorial("Managing a fleet", text, [GetMap().GetScreenUi().ShipDockButton, GetMap().GetScreenUi().RegroupButton], false)
			
	TutorialsToShow.clear()

func Land(Spot : MapSpot, ControlledShip : MapShip) -> bool:
	var Instigator = ControlledShip
	if (ControlledShip.Docked):
		Instigator = ControlledShip.Command
	#ControlledShip.HaltShip()
	var PlayedEvent = false
	if (Spot.Event != null and !Spot.Visited):
		var happeningui = load(HappeningUI).instantiate() as HappeningInstance
		happeningui.EventSpot = Spot
		happeningui.HappeningInstigator = Instigator
		GetMap().GetScreenUi().ToggleFullScreen(ScreenUI.ScreenState.FULL_SCREEN)
		await GetMap().GetScreenUi().FullScreenToggleStarted
		Ingame_UIManager.GetInstance().AddUI(happeningui, true)
		happeningui.PresentHappening(Spot.Event)
		#UIEventH.OnScreenUIToggled(false)
		#UIEventH.OnButtonCoverToggled(true)
		happeningui.connect("HappeningFinished", HappeningFinished.bind(ControlledShip))
		PlayedEvent = true
	Spot.OnSpotVisited()
	return PlayedEvent

func HappeningFinished(Recruited : bool, CapmaignFin : bool, Events : Array[OverworldEventData], Ship : MapShip) -> void:

	GetMap().GetScreenUi().ToggleFullScreen(ScreenUI.ScreenState.HALF_SCREEN)
	#else:
		#GetMap().GetScreenUi().ToggleFullScreen(ScreenUI.ScreenState.HALF_SCREEN)
	await GetMap().GetScreenUi().FullScreenToggleStarted
	get_tree().get_nodes_in_group("Happening")[0].queue_free()
	#await GetMap().GetScreenUi().FullScreenToggleFinished
	if (Recruited):
		TutorialsToShow.append(ActionTracker.Action.RECRUIT)
	if (CapmaignFin):
		Ingame_UIManager.GetInstance().CallbackDiag(["Time to head back people. The package has been delivered."], null, "", EndGame, true)
		return
	
	#Save events to play once we left town
	OverworldEventsToShow.append_array(Events)
		
	OnShipLanded(Ship, true)


#Make sure to remove all items that their cards have been used
#TODO fix this, ammo that wasnt brought into fight cause of lack of weapons will be deleted DONE 
func FigureOutInventory(CharInv : CharacterInventory, Cards : Array[CardStats]):
	#get inventory contents, make sure to duplicate so that removing elements doesent fuck with this
	var Contents = CharInv.GetInventoryContents().duplicate()
	for It : Item in Contents.keys():
		if (It is AmmoItem and !CharInv.HasWeapon(It.WType)):
			continue
			
		for g in Contents[It]:
			#if item doesent provide a card then it def didnt get used
			if (It.CardProviding.size() > 0):
				for c in It.CardProviding:
				#if it did remove it from dictionary and leave ininside inventory
					var CartToCompare = c.duplicate() as CardStats
					CartToCompare.Tier = It.Tier
					
					var CardToRemove : CardStats
					for C in Cards:
						if (C.IsSame(CartToCompare)):
							CardToRemove = C
							break
					if (CardToRemove != null):
						Cards.erase(CardToRemove)
					
				#if it was used and we cant find it in the dictionary then remove it from inventory
					else:
						CharInv.RemoveItem(It)

#--------------------------------------------------------
func GameLost(reason : String):
	get_tree().paused = true
	$Map/SubViewportContainer/ViewPort/InScreenUI/Control3/PanelContainer.visible = true
	$Map/SubViewportContainer/ViewPort/InScreenUI/Control3/PanelContainer/VBoxContainer/Label.text = reason

func EndGame() -> void:
	#GetMap().GetScreenUi().CloseScreen()
	#await GetMap().GetScreenUi().FullScreenToggleStarted
	WRLD_OnGameEnded.emit()

func EndPrologue() -> void:
	ActionTracker.GetInstance().OnPrologueFinished()
	GetMap().GetScreenUi().CloseScreen()
	await GetMap().GetScreenUi().FullScreenToggleStarted
	
	var ProgEnd = PrologueEndScreen.instantiate() as PrologueEnd
	AchievementManager.GetInstance().IncrementStatInt("PROFIN", 1)
	GetMap().GetScreenUi().add_child(ProgEnd)
	await ProgEnd.Finished
	WRLD_OnGameEnded.emit()

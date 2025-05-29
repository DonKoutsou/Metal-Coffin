extends SubViewportContainer

class_name Card_Fight
#/////////////////////////////////////////////////////////////
 #██████  █████  ██████  ██████      ███████ ██  ██████  ██   ██ ████████ 
#██      ██   ██ ██   ██ ██   ██     ██      ██ ██       ██   ██    ██    
#██      ███████ ██████  ██   ██     █████   ██ ██   ███ ███████    ██    
#██      ██   ██ ██   ██ ██   ██     ██      ██ ██    ██ ██   ██    ██    
 #██████ ██   ██ ██   ██ ██████      ██      ██  ██████  ██   ██    ██    
#/////////////////////////////////////////////////////////////
#When a player fleet comed in contact with an enemy one a turn based fight takes place
#Player has acces to weapons present in the current fleet that is fighting
#Each turn player select the actions of his ships and then based on speed each ship doese their actions
#Any atack can have a counter, so a barrage from the machine guns can be "blocked" from an enemy doing evasive manuvers
#/////////////////////////////////////////////////////////////
@export var CardScene : PackedScene
@export var ShipVizScene : PackedScene
@export var ShipVizScene2 : PackedScene
@export var AtackTime : PackedScene
@export var FightGame : PackedScene
@export var CardThing : PackedScene
@export var DamageFloater : PackedScene
#Animation of the atack
@export var ActionAnim : PackedScene
#Scene that shows the stats of the fight
@export var EndScene : PackedScene
@export var CardFightShipInfoScene : PackedScene
@export var CardPlecementSound : AudioStream
@export var RemoveCardSound : AudioStream
@export_group("Plecement Referances")
#Once card is selected to play from player its placed here
@export var SelectedCardPlecement : Control
#Animation of used cards will be placed here
@export var AnimationPlecement : Control
#Container for Enemy ship UI
@export var EnemyShipVisualPlecement : Control
#Container for Player ship UI
@export var PlayerShipVisualPlecement : Control
#UI for selecting a target
@export var TargetSelect : CardFightTargetSelection
#UI for selecting a card to discard
@export var CardSelect : CardFightDiscardSelection
#UI for action declaration
@export var ActionDeclaration : ActionDeclarationUI
@export var HandAmmountLabel : Label
@export var Cloud : ColorRect
@export var DiscardP : DiscardPileUI
@export var DeckP : DeckPileUI
#Showing size of player fleet
@export var PlayerFleetSizeLabel : Label
#Showing size of enemy fleet
@export var EnemyFleetSizeLabel : Label
#UI showing the name of whoever's turn it is
@export var CurrentPlayerLabel : Label
@export_group("FightSettings")
@export var StartingCardAmm : int = 5
@export var MaxCardsInHand : int = 10
@export var MaxCombatants : int = 5
@export var TurnEnergy : int = 10
@export_group("Event Handlers")
@export var UIEventH : UIEventHandler

var ExternalUI : ExternalCardFightUI

#Stats kept to show at the end screen
var DamageDone : float = 0
var DamageGot : float = 0
var DamageNeg : float = 0
var FundsToWin : int = 0

#All ships are placed here based on their Speed stat, Once the turn starts this array is used for the turns
var ShipTurns : Array[BattleShipStats]
var CurrentTurn : int = 0

#Combatants are ships fighting atm, ships from reserves will be pulled to fill combatants when they are less than MaxCombatants
var PlayerReserves : Array[BattleShipStats]
var PlayerCombatants : Array[BattleShipStats]

var EnemyReserves : Array[BattleShipStats]
var EnemyCombatants : Array[BattleShipStats]

#Decks holding info about cards in hand/discard pile/deck pile
var PlayerDecks : Dictionary[BattleShipStats, Deck]
var EnemyDecks : Dictionary[BattleShipStats, Deck]

#List of all UI for each ship combatants, they are created once a ship is added from reserves to combatants
var ShipsViz : Dictionary[BattleShipStats, CardFightShipViz2]

#Once a ship pickes a move its saved here and this list is used to perform the action on the action perform phase
var ActionList = CardFightActionList.new()


var SelectingTarget : bool = false
var EnemyPickingMove : bool = false
var PlayerPerformingMove : bool = false
var PickingMoves : bool = false
var CurrentPhase : CardFightPhase

enum CardFightPhase{
	ACTION_PICK,
	ACTION_PERFORM,
}

signal CardFightEnded(Survivors : Array[BattleShipStats])

func _ready() -> void:
	CurrentPlayerLabel.visible = false
	
	ExternalUI = ExternalCardFightUI.GetInstacne()
	ExternalUI.RegisterFight(self)
	ExternalUI.OnDeckPressed.connect(_on_deck_button_pressed)
	ExternalUI.OnEndTurnPressed.connect(PlayerActionSelectionEnded)
	ExternalUI.OnShipFallbackPressed.connect(_on_switch_ship_pressed)
	ExternalUI.OnPullReserves.connect(_on_pull_reserves_pressed)
	MusicManager.GetInstance().SwitchMusic(true)
	ExternalUI.GetEnergyBar().Init(TurnEnergy)
	ExternalUI.GetReserveBar().Init(0)
	
	PlayerActionPickingEnded.connect(CurrentPlayerTurnEnded)
	EnemyActionPickedEnded.connect(CurrentEnemyTurnEnded)
	
	CreateDecks()
	
	var EnReservesAmm : int = EnemyReserves.size()
	for g in min(MaxCombatants, EnReservesAmm):
		var NewCombatant = EnemyReserves.pick_random()
		EnemyCombatants.append(NewCombatant)
		EnemyReserves.erase(NewCombatant)
		CreateShipVisuals(NewCombatant, false)
	var PlReservesAmm : int = PlayerReserves.size()
	for g in min(MaxCombatants, PlReservesAmm):
		var NewCombatant = PlayerReserves.pick_random()
		PlayerCombatants.append(NewCombatant)
		PlayerReserves.erase(NewCombatant)
		CreateShipVisuals(NewCombatant, true)
	#Add all ships to turn array and sort them
	ShipTurns.append_array(PlayerCombatants)
	ShipTurns.append_array(EnemyCombatants)

	
	ShipTurns.sort_custom(speed_comparator)
	
	UpdateFleetSizeAmmount()
	#Create the visualisation for each ship, basicly their stat holder

	DeckP.visible = false
	DiscardP.visible = false
	ExternalUI.ToggleEnergyVisibility(false)
	HandAmmountLabel.visible = false

	Helper.GetInstance().CallLater(StartFight, 2)


var cloudtime : float = 0
func _physics_process(delta: float) -> void:
	cloudtime += delta
	Cloud.material.set_shader_parameter("custom_time", cloudtime)


func StartFight() -> void:
	ActionDeclaration.DoActionDeclaration("Fight Start", 2)
	ActionDeclaration.ActionDeclarationFinished.connect(IntroDeclarationFinished)


func IntroDeclarationFinished() -> void:
	ActionDeclaration.ActionDeclarationFinished.disconnect(IntroDeclarationFinished)
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.CARD_FIGHT)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.CARD_FIGHT_SPEED_EXPLENATION)
		await ActionTracker.GetInstance().ShowTutorial("Dog Fight", "Close quarters combat is conducted in two distinct phases: the [color=#ffc315]Action Picking Phase[/color] and the [color=#ffc315]Action Performing Phase[/color]. Each ship has their [color=#ffc315]deck[/color] composed out of the parts that exist on the ship. At any given time, a maximum of three ships from each side can engage in combat.\n\nWhen a ship is destroyed, it is immediately replaced by another from the fleet. [color=#ffc315]Victory[/color] is achieved when one side eliminates all enemy ships.\n\nHave faith in your crew captains and good luck!", [], true)
	
	call_deferred("RunTurn")


func ReplaceShip(Ship : BattleShipStats) -> void:
	var Friendly = IsShipFriendly(Ship)
	
	var Viz = GetShipViz(Ship)
	await Viz.ShipDestroyed()
	ShipsViz.erase(Ship)
	
	Viz.get_parent().remove_child(Viz)
	add_child(Viz)
	
	ActionList.RemoveShip(Ship)
	
	var TurnPosition = ShipTurns.find(Ship)
	ShipTurns.erase(Ship)
	
	
	
	if (Friendly):
		var Index = PlayerCombatants.find(Ship)
		PlayerCombatants.erase(Ship)
		if (PlayerReserves.size() > 0):
			var NewCombatant = PlayerReserves.pick_random()
			PlayerCombatants.insert(Index, NewCombatant)
			PlayerReserves.erase(NewCombatant)
			
			ShipTurns.insert(TurnPosition, NewCombatant)
			#ShipTurns.sort_custom(speed_comparator)
			CreateShipVisuals(NewCombatant, true)
		else:
			PlayerReserves.insert(Index, null)
	else:
		var Index = EnemyCombatants.find(Ship)
		EnemyCombatants.erase(Ship)
		
		if (EnemyReserves.size() > 0):
			var NewCombatant = EnemyReserves.pick_random()
			EnemyCombatants.insert(Index, NewCombatant)
			EnemyReserves.erase(NewCombatant)
			
			ShipTurns.insert(TurnPosition, NewCombatant)
			#ShipTurns.sort_custom(speed_comparator)
			CreateShipVisuals(NewCombatant, false)
		else:
			EnemyCombatants.insert(Index, null)
	UpdateFleetSizeAmmount()

func CheckForReserves() -> void:
	if (PlayerCombatants.size() < MaxCombatants and PlayerReserves.size() > 0):
		var NewCombatant = PlayerReserves.pick_random()
		PlayerCombatants.append(NewCombatant)
		PlayerReserves.erase(NewCombatant)
		
		ShipTurns.append(NewCombatant)
		ShipTurns.sort_custom(speed_comparator)
		CreateShipVisuals(NewCombatant, true)
	if (EnemyCombatants.size() < MaxCombatants and EnemyReserves.size() > 0):
		var NewCombatant = EnemyReserves.pick_random()
		EnemyCombatants.append(NewCombatant)
		EnemyReserves.erase(NewCombatant)
		
		ShipTurns.append(NewCombatant)
		ShipTurns.sort_custom(speed_comparator)
		CreateShipVisuals(NewCombatant, false)
	
	UpdateFleetSizeAmmount()


func CreateDecks() -> void:
	#Create the deck
	var Ships : Array[BattleShipStats]
	Ships.append_array(PlayerReserves)
	Ships.append_array(EnemyReserves)
	for g in Ships:
		var D = Deck.new()
		
		var ShipCards = g.Cards.keys()
		
		for Crd : CardStats in ShipCards:
			var Amm = 0
			Amm = g.Cards[Crd]
				
			for Dup in Amm:
				D.DeckPile.append(Crd)

		#Create Hand
		D.DeckPile.shuffle()
		for Hand in StartingCardAmm:
			var C = D.DeckPile.pop_front()
			D.Hand.append(C)
			
		if (IsShipFriendly(g)):
			PlayerDecks[g] = D
		else:
			EnemyDecks[g] = D


#function to sort battle ships based on their speed
static func speed_comparator(a, b):
	if a.GetSpeed() > b.GetSpeed():
		return true  # -1 means 'a' should appear before 'b'
	elif a.GetSpeed()< b.GetSpeed():
		return false  # 1 means 'b' should appear before 'a'
	return true


func CreateShipVisuals(BattleS : BattleShipStats, Friendly : bool) -> void:
	var t = ShipVizScene2.instantiate() as CardFightShipViz2

	t.SetStats(BattleS, Friendly)
	
	var Parent : Control
	
	if (Friendly):
		for g in PlayerShipVisualPlecement.get_children():
			if (g is HBoxContainer and g.get_child_count() == 1):
				Parent = g
				break
				
		Parent.add_child(t)
	else :
		for g in EnemyShipVisualPlecement.get_children():
			if (g is HBoxContainer and g.get_child_count() == 1):
				Parent = g
				break
		
		Parent.add_child(t)
		Parent.move_child(t, 0)
	
	ShipsViz[BattleS] = t
	NewTurnStarted.connect(t.OnNewTurnStarted)


func ShipVizPressed(Ship : BattleShipStats) -> void:
	var Scene = CardFightShipInfoScene.instantiate() as CardFightShipInfo
	Scene.SetUpShip(Ship)
	add_child(Scene)


#/////////////////////////////////////////////////
#██████  ██   ██  █████  ███████ ███████ ███████ 
#██   ██ ██   ██ ██   ██ ██      ██      ██      
#██████  ███████ ███████ ███████ █████   ███████ 
#██      ██   ██ ██   ██      ██ ██           ██ 
#██      ██   ██ ██   ██ ███████ ███████ ███████ 
#/////////////////////////////////////////////////
#1
#First phase is action pick phase. Each ship based on their speed picks their actions based on how much energy they have
#If its player ship, the atacks/deffences the ship has apear so player can choose.
#If its enemy ship it is determined randomly what atacks they will do in EnemyActionSelection function
#2
#Second phase is actions perform phase. Each ship based on their speed do the actions they chose durring previus phase
#An animation is played for each atacking action.
#3
#Third phase is DOT aplication phase. If any ship has a DOT on them (fire etc...) the damage of that dot is applied
#4
#Forth phase is cleanup phase, all unused card are refunded (an atack that was destined for a target that got killed) and the turn is reastarted
#/////////////////////////////////////////////////
var GameOver : bool = false

signal NewTurnStarted
signal PlayerActionPickingEnded
signal EnemyActionPickedEnded

func RunTurn() -> void:
	ActionDeclaration.DoActionDeclaration("Action Pick Phase", 2)
	ActionDeclaration.ActionDeclarationFinished.connect(PickPhase)
	#await DoActionDeclaration("Action Pick Phase", 2)


func PickPhase() -> void:
	ActionDeclaration.ActionDeclarationFinished.disconnect(PickPhase)
	CurrentPhase = CardFightPhase.ACTION_PICK
	CurrentTurn = 0
	
	NewTurnStarted.emit()
	
	ProgressBuffsForCurrentShip()

func ProgressBuffsForCurrentShip() -> void:
	if (CurrentTurn < ShipTurns.size()):
		var CurrentShip = GetCurrentShip()
		var viz = GetShipViz(CurrentShip)
		var ExpiredBuffs = CurrentShip.UpdateBuffs()
		
		UpdateShipStats(CurrentShip)
		CurrentTurn = CurrentTurn + 1
		
		if (ExpiredBuffs.size() > 0):
			var d : Floater
			for g in ExpiredBuffs:
				d = DamageFloater.instantiate()
				d.modulate = Color(1,0,0,1)
				d.text = g + " +\nExpired"
				add_child(d)
				d.global_position = (viz.global_position + (viz.size / 2)) - d.size / 2
			d.Ended.connect(ProgressBuffsForCurrentShip)
		else:
			ProgressBuffsForCurrentShip()
		
	else:
		PickPhaseStart()
	
	
func PickPhaseStart() -> void:
	CurrentTurn = 0
	
	ShipTurns.sort_custom(speed_comparator)
	
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.CARD_FIGHT_ACTION_PICK)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.CARD_FIGHT_ACTION_PICK)
		await ActionTracker.GetInstance().ShowTutorial("Action Picking Phase", "During the Action Picking Phase, each ship selects its moves for the upcoming Action Performing Phase. Ships with higher speed have the advantage of choosing and executing their moves first.\nRemember that every offensive action has a corresponding defensive option, so it’s crucial to protect your ship while maintaining a strong offensive stance.", [], true)

	CurrentPlayerLabel.visible = true
	
	StartCurrentShipsPickTurn()


func StartCurrentShipsPickTurn() -> void:
	if (CurrentTurn < ShipTurns.size()):
		var Ship = GetCurrentShip()
		CurrentPlayerLabel.text = "{0} picking".format([Ship.Name])
		ActionDeclaration.DoActionDeclaration(Ship.Name + "'s turn", 1.5)
		EnemyPickingMove = !IsShipFriendly(Ship)
		ActionDeclaration.ActionDeclarationFinished.connect(RunShipsTurn.bind(Ship))
	else:
		StartActionPerform()


func RunShipsTurn(Ship : BattleShipStats) -> void:
	ActionDeclaration.ActionDeclarationFinished.disconnect(RunShipsTurn)
	
	var viz = GetShipViz(Ship)
	viz.Enable()
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.CARD_FIGHT_SPEED_EXPLENATION)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.CARD_FIGHT_SPEED_EXPLENATION)
		await ActionTracker.GetInstance().ShowTutorial("Ship Speed", "Each ships has a speed stat. Faster ships get to choose and also get to perform their moves first.", [viz], true)
	
	ActionList.AddShip(Ship)
	if (IsShipFriendly(Ship)):
		DeckP.visible = true
		DiscardP.visible = true
		ExternalUI.ToggleEnergyVisibility(true)
		if (!ActionTracker.IsActionCompleted(ActionTracker.Action.CARD_FIGHT_ENERGY)):
			ActionTracker.OnActionCompleted(ActionTracker.Action.CARD_FIGHT_ENERGY)
			await ActionTracker.GetInstance().ShowTutorial("Energy", "Each card has a cost that needs to be payed in order to use it. \nEach ship starts their action picking phase with 10 energy to spare. \nAny unused energy is lost at the end of turn.", [ExternalUI.GetEnergyBar()], true)

		if (!ActionTracker.IsActionCompleted(ActionTracker.Action.CARD_FIGHT_RESERVES)):
			ActionTracker.OnActionCompleted(ActionTracker.Action.CARD_FIGHT_RESERVES)
			await ActionTracker.GetInstance().ShowTutorial("Energy Reserves", "Some cards can provide a ship with energy reserves. Energy reserves are kept until the player decides to use them and can be accumulated indefinetly. At any point the 'Pull Reserves' is pressed any amount of reserves kept on the ship will be lost and gained as energy to use on that turn.", [ExternalUI.GetReserveBar()], true)
		
		HandAmmountLabel.visible = true
		
		await RestartCards()
		
		PickingMoves = true
	else:
		EnemyPickingMove = true
		HandleDrawCardEnemy(Ship)
		EnemyActionSelection(Ship)
	
	


func OnCardSelected(C : Card) -> bool:
	
	if (SelectingTarget or EnemyPickingMove or Shuffling):
		return false
	
	var Ship = GetCurrentShip()
	
	if (Ship.Energy < C.GetCost()):
		ExternalUI.GetEnergyBar().NotifyNotEnough()
		PopUpManager.GetInstance().DoFadeNotif("Not enough energy")
		return false
	
	PlayerPerformingMove = true
	
	var deck = GetShipDeck(Ship)
	
	UpdateEnergy(Ship, Ship.Energy - C.GetCost(), true)
	print("{0} has been removed from {1}'s hand.".format([C.CStats.CardName, Ship.Name]))
	deck.Hand.erase(C.CStats)
	
	if (C.CStats.OnPerformModule != null):
		var Action : CardStats

		Action = C.CStats
		
		var c = CardScene.instantiate() as Card
		
		var ShipAction = CardFightAction.new()
		ShipAction.Action = Action
		
		var Mod = Action.OnPerformModule
		
		var CardPosition = C.global_position
		
		if (Mod is OffensiveCardModule):
			if (Mod is EnergyOffensiveCardModule):
				var NewMod = Mod.duplicate()
				NewMod.StoredEnergy = Ship.Energy
				UpdateEnergy(Ship, 0, true)
				Action.OnPerformModule = NewMod
			
			var targets = await HandleTargets(Mod, Ship)
			for g in targets:
				var TargetViz = GetShipViz(GetTarget(g))
				if (TargetViz == null):
					continue
				c.TargetLocs.append(TargetViz.GetShipPos())
			ShipAction.Targets.append_array(targets)
		
		
		c.SetCardBattleStats(Ship, Action)
		
		c.connect("OnCardPressed", RemoveCard)
		
		SelectedCardPlecement.add_child(c)
	
		var viz = GetShipViz(Ship)
		viz.ActionPicked(Action.Icon)
		ActionList.AddAction(Ship, ShipAction)
		
		await DoCardPlecementAnimation(Ship, c, CardPosition)
		#call_deferred("DoCardPlecementAnimation", Ship, c, CardPosition)
		C.get_parent().queue_free()

	else:
		var pos = C.global_position
		var parent = C.get_parent()
		parent.remove_child(C)
		parent.queue_free()
		add_child(C)
		C.global_position = pos
		C.KillCard(0.5, true)
		
		var S = DeletableSoundGlobal.new()
		S.stream = RemoveCardSound
		S.autoplay = true
		add_child(S)
		S.volume_db = -10
		
		if (!C.CStats.Consume):
			print("{0} has been added to {1}'s discard pile.".format([C.CStats.CardName, Ship.Name]))
			deck.DiscardPile.append(C.CStats)
			DiscardP.OnCardDiscarded(C.global_position + (C.size / 2))
	
	
	
	if (C.CStats.Consume):
		var ShipCards = Ship.Cards
		ShipCards[C.CStats] -= 1
		if (ShipCards[C.CStats] == 0):
			ShipCards.erase(C.CStats)
	
	#var Stats  = C.CStats
	await HandleModules(Ship, C.CStats)

	UpdateHandAmount(deck.Hand.size())
	PlayerPerformingMove = false

	return true


func RemoveCard(C : Card) -> void:
	if (SelectingTarget or EnemyPickingMove):
		return
	
	var CurrentShip = GetCurrentShip()
	
	var D = PlayerDecks[CurrentShip]
	
	if (D.Hand.size() == MaxCardsInHand):
		NotifyFullHand()
		return
	
	var Stats = C.CStats
	
	if (Stats.OnUseModules.size() > 0):
		return
	
	C.disconnect("OnCardPressed", RemoveCard)

	if (Stats.Consume):
		var ShipCards = CurrentShip.Cards
		var HasCard = false
		for g in ShipCards.keys():
			#print("Comparing {0} with {1}".format([g.resource_path, C.CStats.resource_path]))
			if (g.CardName == Stats.CardName):
				HasCard = true
				ShipCards[g] += 1
				break
		if (!HasCard):
			ShipCards[Stats] = 1
	
	var viz = GetShipViz(CurrentShip)
	viz.ActionRemoved(Stats.Icon)
	ActionList.RemoveActionFromShip(CurrentShip, Stats)
	
	var PerformModule = Stats.OnPerformModule
	if (PerformModule is EnergyOffensiveCardModule):
		UpdateEnergy(CurrentShip, CurrentShip.Energy + PerformModule.StoredEnergy, true)
		PerformModule.StoredEnergy = 0
	else:
		UpdateEnergy(CurrentShip, CurrentShip.Energy + C.GetCost(), true)
	
	
	D.Hand.append(Stats)
	UpdateHandAmount(D.Hand.size())
	
	#UpdateHandCards()
	var c = CardScene.instantiate() as Card
	c.SetCardBattleStats(CurrentShip, Stats)
	#c.connect("OnCardPressed", OnCardSelected)
	
	ExternalUI.OnCardDrawn(c)

	#call_deferred("DoCardPlecementAnimation", c, C.global_position)
	
	C.queue_free()


func EnemyActionSelection(Ship : BattleShipStats) -> void:
	Ship.Energy = TurnEnergy + Ship.EnergyReserves
	Ship.EnergyReserves = 0
	var viz = GetShipViz(Ship)
	var EnemyDeck = EnemyDecks[Ship]
	
	if (GetShipViz(Ship).IsOnFire()):
		var ExtinguishAction
		for g : CardStats in EnemyDeck.Hand:
			if (g.CardName == "Extinguish fires"):
				ExtinguishAction = g
				Ship.Energy -= ExtinguishAction.Energy
				#TODO fix this

				await HandleModulesEnemy(Ship, g)

				EnemyDeck.Hand.erase(g)
				print("{0} has been added to {1}'s discard pile.".format([g.CardName, Ship.Name]))
				EnemyDeck.DiscardPile.append(g)
				break
	
	var AvailableActions = EnemyDeck.Hand.duplicate()
	var Actions = ""
	for g : CardStats in AvailableActions:
		Actions += g.CardName + ", "
	print("{0}'s hand : {1}".format([Ship.Name, Actions]))
	
	var t = func CheckIfToDraw(Actions : Array[CardStats]) -> Array[CardStats]:
		if (Actions.size() == 0 and Ship.Energy > 1 and EnemyDeck.Hand.size() < MaxCardsInHand):
			print("{0} draws a card".format([Ship.Name]))
			HandleDrawCardEnemy(Ship)
			Actions.clear()
			return EnemyDeck.Hand
		return Actions
		
	while (AvailableActions.size() > 0):
		var Action = (AvailableActions.pick_random() as CardStats)
		
		print("{0} tries to player card {1}".format([Ship.Name, Action.CardName]))
		
		if (!Action.AllowDuplicates and ActionList.ShipHasAction(Ship, Action)):
			AvailableActions.erase(Action)
			AvailableActions = t.call(AvailableActions)

		else: if (Action.CardName == "Extinguish fires" or Action.Energy > Ship.Energy):
			print("{0} cant use {1}, not enough energy".format([Ship.Name, Action.CardName]))
			AvailableActions.erase(Action)
			AvailableActions = t.call(AvailableActions)
		
		#for g in Action.OnUseModules:
			#if (g is DeffenceCardModule):
				#if (!g.SelfUse and EnemyCombatants.size() == 0):
					#AvailableActions.erase(Action)
					#AvailableActions = t.call(AvailableActions)
			
		else:
			print("{0} uses {1}".format([Ship.Name, Action.CardName]))
			var SelectedAction : CardStats = Action.duplicate()
			
			Ship.Energy -= SelectedAction.Energy
			
			EnemyDeck.Hand.erase(Action)
			#EnemyDeck.DiscardPile.append(Action)
			AvailableActions.erase(Action)

			
			await HandleModulesEnemy(Ship, SelectedAction)
			
			if (SelectedAction.OnPerformModule == null):
				print("{0} has been added to {1}'s discard pile.".format([SelectedAction.CardName, Ship.Name]))
				EnemyDeck.DiscardPile.append(SelectedAction)
			else:
				await DoCardSelectAnimation(SelectedAction, Ship, GetShipViz(Ship))
				
				var ShipAction = CardFightAction.new()
				ShipAction.Action = SelectedAction

				ShipAction.Targets = await HandleTargets(Action.OnPerformModule, Ship)
				viz.ActionPicked(SelectedAction.Icon)
				ActionList.AddAction(Ship, ShipAction)

			AvailableActions = t.call(AvailableActions)
			
		print("{0} ended their turn with {1} exess energy".format([Ship.Name, Ship.Energy]))
	EnemyActionPickedEnded.emit()


func PlayerActionSelectionEnded() -> void:
	if (SelectingTarget or !PickingMoves or EnemyPickingMove or PlayerPerformingMove or CurrentPhase != CardFightPhase.ACTION_PICK):
		return
	#GetShipViz(ShipTurns[CurrentTurn]).Dissable()
	PlayerActionPickingEnded.emit()


func CurrentEnemyTurnEnded() -> void:
	var Ship = GetCurrentShip()
	var viz = GetShipViz(Ship)
	viz.Dissable()
	viz.OnActionsPerformed()
	EnemyPickingMove = false
	CurrentTurn = CurrentTurn + 1
	StartCurrentShipsPickTurn()


func CurrentPlayerTurnEnded() -> void:
	PickingMoves = false
	ClearCards()
	
	DeckP.visible = false
	DiscardP.visible = false

	HandAmmountLabel.visible = false
		
	var Ship = GetCurrentShip()
	var viz = GetShipViz(Ship)
	viz.Dissable()
	viz.OnActionsPerformed()
	
	CurrentTurn = CurrentTurn + 1
	
	StartCurrentShipsPickTurn()


func StartActionPerform() -> void:
	
	CurrentPlayerLabel.visible = false
	ClearCards()
	
	#Sort ships again to make sure speed buffs are taken into account
	ShipTurns.sort_custom(speed_comparator)

	DeckP.visible = false
	DiscardP.visible = false
	HandAmmountLabel.visible = false
	
	CurrentPhase = CardFightPhase.ACTION_PERFORM
	ActionDeclaration.DoActionDeclaration("Action Perform Phase", 2)
	ActionDeclaration.ActionDeclarationFinished.connect(ActionPerformPhase)


func ActionPerformPhase() -> void:
	
	ActionDeclaration.ActionDeclarationFinished.disconnect(ActionPerformPhase)

	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.CARD_FIGHT_ACTION_PERFORM)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.CARD_FIGHT_ACTION_PERFORM)
		ActionTracker.GetInstance().ShowTutorial("Action Perform Phase", "In the Action Perform Phase each ship performs the moves they've picked in the Action Pick Phase.\nIn the end of the phase any unused card, like an extra deffensive card, will be returned to the discard pile.", [], true)
	
	CurrentPlayerLabel.visible = true
	CurrentTurn = 0
	
	StartCurrentShipsPerformTurn()


func StartCurrentShipsPerformTurn() -> void:
	if (GameOver):
		return
		
	if (CurrentTurn < ShipTurns.size()):
		var Ship = GetCurrentShip()
		CurrentPlayerLabel.text = "{0} performing actions".format([Ship.Name])

		PerformActions(Ship)
		return
		
	CurrentPlayerLabel.visible = false
	
	CurrentTurn = 0
	
	DoCurrentShipFireDamage()


func DoCurrentShipFireDamage() -> void:
	if (CurrentTurn < ShipTurns.size()):
		var CurrentShip = GetCurrentShip()

		var viz = GetShipViz(CurrentShip)
		if (viz.IsOnFire()):
			
			var d = DamageFloater.instantiate() as Floater
			d.text = "Fire Damage"
			viz.add_child(d)
			d.global_position = (viz.global_position + (viz.size / 2)) - d.size / 2
			
			var GameEnded = DamageShip(CurrentShip, 10, false, true)
			
			if (GameEnded):
				return
			
			CurrentTurn = CurrentTurn + 1
			
			d.Ended.connect(DoCurrentShipFireDamage)
				
			return
		
		else:
			CurrentTurn = CurrentTurn + 1
			DoCurrentShipFireDamage()
	else:
		FireDamageFinished()


func FireDamageFinished() -> void:
	if (GameOver):
		return
	RefundUnusedCards()
	ActionList.Clear()
	
	call_deferred("RunTurn")

func PerformActions(Ship : BattleShipStats) -> void:
	#var ActionsToBurn : Array[CardFightAction]
	var viz = GetShipViz(Ship)
	for g in viz.get_parent().get_children():
		if (g != viz):
			var tw = create_tween()
			tw.set_ease(Tween.EASE_OUT)
			tw.set_trans(Tween.TRANS_QUAD)
			tw.tween_property(g, "custom_minimum_size", Vector2(90, 0), 0.2)
			tw.finished.connect(PerformNextActionForShip.bind(Ship, 0))
			#g.visible = true


func PerformNextActionForShip(Ship : BattleShipStats, ActionIndex : int) -> void:
	var Dec = GetShipDeck(Ship)
	var Friendly = IsShipFriendly(Ship)
	var viz = GetShipViz(Ship)
	
	var ShipActions = ActionList.GetShipsActions(Ship)
	
	if (ShipActions.size() - 1 < ActionIndex):
		PerformTurnFinished()
		return
	
	var ShipAction = ShipActions[ActionIndex] as CardFightAction
	var Action = ShipAction.Action

	var Targets = ShipAction.Targets
	
	var TargetShips : Array[BattleShipStats]
	
	for g in Targets:
		var T = GetTarget(g)
		if (T != null):
			TargetShips.append(T)
	
	if (TargetShips.size() == 0):
		ActionIndex += 1
		PerformNextActionForShip(Ship, ActionIndex)
	else:
		var Mod = Action.OnPerformModule

		if (Mod is OffensiveCardModule):

			#ActionsToBurn.append(ShipAction)
			ActionList.RemoveActionFromShip(Ship, Action)
			var Counter : CardStats
			var AtackType = Mod.AtackType
			#var HasDeff = false
			
			var anim = ActionAnim.instantiate() as CardOffensiveAnimation
			#anim.DrawnLine = true
			AnimationPlecement.add_child(anim)
			AnimationPlecement.move_child(anim, 1)

			#List containing targets and a bool saying if target has def
			var TargetList : Dictionary[BattleShipStats, Dictionary]
			
			for g in TargetShips:

				for Act : CardFightAction in ActionList.GetShipsActions(g):
					var mod = Act.Action.OnPerformModule
					if (mod is CounterCardModule):
						if (mod.CounterType == AtackType):
							Counter = Act.Action
							break
					
				var Data : Dictionary
				Data["Def"] = Counter
				Data["Viz"] = GetShipViz(g)
				TargetList[g] = Data
			
			
			if (!Action.ShouldConsume()):
				print("{0} has been added to {1}'s discard pile.".format([Action.CardName, Ship.Name]))
				Dec.DiscardPile.append(Action)
				if (Friendly):
					DiscardP.UpdateDiscardPileAmmount(Dec.DiscardPile.size())
					DiscardP.visible = true
					
					anim.AtackCardDestroyed.connect(DiscardP.OnCardDiscarded)
			
			for g in TargetList:
				var Def = TargetList[g]["Def"]
				
				if (Def != null):
					var TargetViz = TargetList[g]["Viz"]
					TargetViz.ActionRemoved(Counter.Icon)
					ActionList.RemoveActionFromShip(g, Counter)
					if (!Counter.ShouldConsume()):
						var TargetDeck = GetShipDeck(g)
						print("{0} has been added to {1}'s discard pile.".format([Counter.CardName, g.Name]))
						TargetDeck.DiscardPile.append(Counter)
						if (!Friendly):
							DiscardP.UpdateDiscardPileAmmount(TargetDeck.DiscardPile.size())
							DiscardP.visible = true
							anim.DeffenceCardDestroyed.connect(DiscardP.OnCardDiscarded)
							
					if (!Friendly):
						DamageNeg += Mod.GetFinalDamage(Ship)

			viz.ActionRemoved(Action.Icon)
			
			anim.DoOffensive(Action, Mod, TargetList, Ship, Friendly)
			anim.AnimationFinished.connect(PerformAnimationFinished.bind(Ship, ActionIndex))
			
			
			var DamageCallables : Array[Callable]
			
			for g in TargetList:
				#print("Atack Started")
				
				#anim.AtackConnected.connect()
				#print("Atack connected")
				if (TargetList[g]["Def"] == null):
					var c = Callable.create(self, "DamageShip").bind(g, Mod.GetFinalDamage(Ship), Mod.CauseFile, Mod.SkipShield)
					DamageCallables.append(c)
					#anim.AtackConnected.connect(c)
			
			if (DamageCallables.size() > 0):
				anim.AtackConnected.connect(ConnectMoves.bind(DamageCallables))
			
			await anim.AtackConnected
			for g in TargetList:

				if (TargetList[g]["Def"] != null):
					continue
				else:
					for d in Mod.OnSuccesfullAtackModules:
						if (Friendly):
							await HandleModule(Ship, Action, d)
						else:
							await HandleModuleEnemy(Ship, Action, d)
					break
			
		else:
			ActionIndex += 1
			PerformNextActionForShip(Ship, ActionIndex)

func ConnectMoves(C : Array[Callable]) -> void:
	var c = C.pop_front() as Callable
	c.call()
	

func PerformAnimationFinished(Ship : BattleShipStats, ActionIndex : int) -> void:
	DiscardP.visible = false
	PerformNextActionForShip(Ship, ActionIndex)


func PerformTurnFinished() -> void:
	var viz = GetShipViz(GetCurrentShip())
	for g in viz.get_parent().get_children():
		if (g != viz):
			var tw = create_tween()
			tw.set_ease(Tween.EASE_OUT)
			tw.set_trans(Tween.TRANS_QUAD)
			tw.tween_property(g, "custom_minimum_size", Vector2(0, 0), 0.2)
			await tw.finished
	CurrentTurn = CurrentTurn + 1
	StartCurrentShipsPerformTurn()


#Refunds cards that consume inventory items if the card wasnt used in the end
func RefundUnusedCards() -> void:
	for Ship in PlayerCombatants:
		var Acts = ActionList.GetShipsActions(Ship)
		var viz = GetShipViz(Ship)
		for z in Acts:
			var ShipAction = z as CardFightAction
			#if (!ShipAction.Action.ShouldConsume()):
				#continue
			RefundCardToShip(ShipAction.Action, Ship)
			viz.ActionRemoved(ShipAction.Action.Icon)
	for Ship in EnemyCombatants:
		var Acts = ActionList.GetShipsActions(Ship)
		var viz = GetShipViz(Ship)
		for z in Acts:
			var ShipAction = z as CardFightAction
			#if (!ShipAction.Action.ShouldConsume()):
				#continue
			RefundCardToShip(ShipAction.Action, Ship)
			viz.ActionRemoved(ShipAction.Action.Icon)


func RefundCardToShip(C : CardStats, Ship : BattleShipStats):
	print("{0} got refunded a {1} card for not using it.".format([Ship.Name, C.CardName]))
	var deck = GetShipDeck(Ship)
	print("{0} has been added to {1}'s discard pile.".format([C.CardName, Ship.Name]))
	deck.DiscardPile.append(C)


func RestartCards() -> void:
	ClearCards()
	
	var currentship = GetCurrentShip()
	var D = GetShipDeck(currentship)
	
	ExternalUI.GetEnergyBar().ChangeSegmentAmm(TurnEnergy)
	ExternalUI.GetReserveBar().ChangeSegmentAmm(currentship.EnergyReserves)
	
	UpdateEnergy(currentship, TurnEnergy, true)
	UpdateReserves(currentship, currentship.EnergyReserves, true)
	UpdateHandCards()
	
	DiscardP.UpdateDiscardPileAmmount(D.DiscardPile.size())
	DeckP.UpdateDeckPileAmmount(D.DeckPile.size())
	#GetShipViz(ShipTurns[CurrentTurn]).Enable()
	
	HandleDrawCard(currentship)

# CALLED AT THE END. SHOWS ENDSCREEN WITH DATA COLLECTED AND WAITS FOR PLAYER 
func OnFightEnded(Won : bool) -> void:
	var End = EndScene.instantiate() as CardFightEndScene
	End.SetData(Won, FundsToWin, DamageDone, DamageGot, DamageNeg)
	add_child(End)
	PlayerShipVisualPlecement.visible = false
	EnemyShipVisualPlecement.visible = false
	await End.ContinuePressed
	var Survivors : Array[BattleShipStats]
	RefundUnusedCards()
	Survivors.append_array(PlayerCombatants)
	Survivors.append_array(PlayerReserves)
	Survivors.append_array(EnemyCombatants)
	Survivors.append_array(EnemyReserves)
	
	for g in Survivors:
		g.Cards.clear()
		var D = GetShipDeck(g)
		g.Cards = D.GetCardList()
	
	CardFightEnded.emit(Survivors)
	
	MusicManager.GetInstance().SwitchMusic(false)
#/////////////////////////////////////////////////////////////////////
#██   ██  █████  ███    ██ ██████  ██      ███████ ██████  ███████ 
#██   ██ ██   ██ ████   ██ ██   ██ ██      ██      ██   ██ ██      
#███████ ███████ ██ ██  ██ ██   ██ ██      █████   ██████  ███████ 
#██   ██ ██   ██ ██  ██ ██ ██   ██ ██      ██      ██   ██      ██ 
#██   ██ ██   ██ ██   ████ ██████  ███████ ███████ ██   ██ ███████ 
#/////////////////////////////////////////////////////////////////////

func HandleModules(Performer : BattleShipStats, C : CardStats) -> void:
	for Mod in C.OnUseModules.size():
		if (Mod == C.OnUseModules.size() - 1):
			await HandleModule(Performer, C ,C.OnUseModules[Mod])
		else:
			HandleModule(Performer, C ,C.OnUseModules[Mod])
			await Helper.GetInstance().wait(0.2)



func HandleModule(Performer : BattleShipStats, C : CardStats, Mod : CardModule) -> void:
	if (Mod is ResupplyModule):
		await HandleResupply(Performer, C, Mod)
	else :if (Mod is CauseFireModule):
		HandleCauseFire(Performer, C, Mod)
	else : if (Mod is ReserveModule):
		await HandleReserveSupply(Performer, C, Mod)
	else : if (Mod is ReserveConversionModule):
		await HandleReserveConversion(Performer, C, Mod)
	else : if (Mod is MaxReserveModule):
		await HandleMaxReserveSupply(Performer, C, Mod)
	else : if (Mod is DrawCardModule):
		HandleDrawDriscard(Performer, Mod)
	else : if (Mod is CardSpawnModule):
		var CardToSpawn = Mod.CardToSpawn
		HandleDrawSpecificCard(Performer, CardToSpawn)
	else : if (Mod is MultiCardSpawnModule):
		HandleMultiDrawSpecific(Performer, C, Mod)
	else: if (Mod is FireExtinguishModule):
		await HandleFireExtinguish(Performer, C, Mod)
	else : if (Mod is BuffModule):
		await HandleBuff(Performer, C, Mod)
	else : if (Mod is DeBuffEnemyModule or Mod is DeBuffSelfModule):
		await HandleDeBuff(Performer, C, Mod)
	else : if (Mod is ShieldCardModule):
		await HandleShield(Performer, C, Mod)
	else : if (Mod is MaxShieldCardModule):
		await HandleMaxShield(Performer, C, Mod)
	else : if (Mod is SelfDamageModule):
		await HandleSelfDamage(Performer, C, Mod)
	else : if (Mod is RecoilDamageModule):
		var AtackMod = C.OnPerformModule as OffensiveCardModule
		await HandleRecoil(Performer, C, AtackMod.GetFinalDamage(Performer), Mod)
	else : if (Mod is StackDamageCardModule):
		await HandleDamageStack(Performer, C, Mod)


func HandleModulesEnemy(Performer : BattleShipStats, C : CardStats) -> void:
	for Mod in C.OnUseModules.size():
		if (Mod == C.OnUseModules.size() - 1):
			await HandleModuleEnemy(Performer, C ,C.OnUseModules[Mod])
		else:
			HandleModuleEnemy(Performer, C ,C.OnUseModules[Mod])
			await Helper.GetInstance().wait(0.2)


func HandleModuleEnemy(Performer : BattleShipStats, C : CardStats,Mod : CardModule) -> void:
	if (Mod is ResupplyModule):
		await HandleResupply(Performer, C, Mod)
	else : if (Mod is ReserveModule):
		await HandleReserveSupply(Performer, C, Mod)
	else : if (Mod is ReserveConversionModule):
		await HandleReserveConversion(Performer, C, Mod)
	else : if (Mod is MaxReserveModule):
		await HandleMaxReserveSupply(Performer, C, Mod)
	else : if (Mod is CauseFireModule):
		await HandleCauseFire(Performer, C, Mod)
	else : if (Mod is DrawCardModule):
		HandleDrawDiscardEnemy(Performer ,Mod)
	else : if (Mod is CardSpawnModule):
		var CardToSpawn = Mod.CardToSpawn
		HandleDrawSpecificCardEnemy(Performer, CardToSpawn)
	else : if (Mod is MultiCardSpawnModule):
		HandleMultiDrawSpecificEnemy(Performer, C, Mod)
	else : if (Mod is FireExtinguishModule):
		await HandleFireExtinguish(Performer, C, Mod)
	else : if (Mod is BuffModule):
		await HandleBuff(Performer, C, Mod)
	else : if (Mod is DeBuffEnemyModule or Mod is DeBuffSelfModule):
		await HandleDeBuff(Performer, C, Mod)
	else : if (Mod is ShieldCardModule):
		await HandleShield(Performer, C, Mod)
	else : if (Mod is MaxShieldCardModule):
		await HandleMaxShield(Performer, C, Mod)
	else : if (Mod is SelfDamageModule):
		await HandleSelfDamage(Performer, C, Mod)
	else : if (Mod is RecoilDamageModule):
		var AtackMod = C.OnPerformModule as OffensiveCardModule
		await HandleRecoil(Performer, C, AtackMod.GetFinalDamage(Performer), Mod)
	else : if (Mod is StackDamageCardModule):
		await HandleDamageStack(Performer, C, Mod)

func HandleDrawDriscard(Performer : BattleShipStats, Mod : DrawCardModule) -> void:
	var D = GetShipDeck(Performer)
			
	var DrawAmmount = Mod.DrawAmmount
	var DiscardAmmount = Mod.DiscardAmmount
	
	var CardsToDraw : Array[Card] = []
	var CardsToDiscard : Array[Card] = []
	
	for g in DrawAmmount:
		if (D.DeckPile.size() <= 0):
			await HandleShuffleDiscardedIntoDeck(D)
		
		var ToDraw = D.DeckPile.pop_front()
		var c = CardScene.instantiate() as Card
		c.SetCardBattleStats(Performer, ToDraw)
		#c.connect("OnCardPressed", OnCardSelected)
		
		DeckP.OnCardDrawn()
		CardsToDraw.append(c)
	
	while CardsToDiscard.size() < DiscardAmmount:
		CardSelect.SetCards(Performer, CardsToDraw)
		SelectingTarget = true
		var ToDiscard : int = await CardSelect.CardSelected
		SelectingTarget = false
		var Ca = CardsToDraw[ToDiscard]
		CardsToDraw.erase(Ca)
		CardsToDiscard.append(Ca)
		print("{0} has been added to {1}'s discard pile.".format([Ca.CStats.CardName, Performer.Name]))
		D.DiscardPile.append(Ca.CStats)
		DeckP.OnCardDrawn()
		DiscardP.OnCardDiscarded(DeckP.global_position)
	
	for g in CardsToDraw:
		
		var Placed = await PlaceCardInPlayerHand(Performer, g)
		await Helper.GetInstance().wait(0.2)
		DeckP.OnCardDrawn()
		
		if (Placed):
			pass
			#call_deferred("DoCardPlecementAnimation", g, DeckP.global_position)
		else:
			g.queue_free()


func HandleDrawDiscardEnemy(Performer : BattleShipStats,Mod : DrawCardModule) -> void:
	var D = EnemyDecks[Performer]
				
	var DrawAmmount = Mod.DrawAmmount
	var DiscardAmmount = Mod.DiscardAmmount
	
	var CardsToDraw : Array[CardStats] = []
	var CardsToDiscard : Array[CardStats] = []
	
	for g in DrawAmmount:
		if (D.DeckPile.size() <= 0):
			await HandleShuffleDiscardedIntoDeck(D)
		
		var ToDraw = D.DeckPile.pop_front()
		CardsToDraw.append(ToDraw)
	
	while CardsToDiscard.size() < DiscardAmmount:
		var ToDiscard = CardsToDraw.pick_random()
		CardsToDraw.erase(ToDiscard)
		CardsToDiscard.append(ToDiscard)
		print("{0} has been added to {1}'s discard pile.".format([ToDiscard.CardName, Performer.Name]))
		D.DiscardPile.append(ToDiscard)
	
	for g in CardsToDraw:
		PlaceCardInEnemyHand(Performer, g)


func HandleResupply(Performer : BattleShipStats, Action : CardStats, Mod : ResupplyModule) -> void:
	var resupplyamm = Mod.ResupplyAmmount

	var Targets = await HandleTargets(Mod, Performer)
	var TargetViz : Array[Control]
	
	var Friendly = IsShipFriendly(Performer)
	
	for g in Targets:
		var TargetShip = GetTarget(g)
		if (TargetShip == null):
			continue
		TargetViz.append(GetShipViz(TargetShip))

		UpdateEnergy(TargetShip, TargetShip.Energy + resupplyamm, TargetShip == Performer and Friendly)
			
	await DoDeffenceAnim(Action, Mod, Performer, TargetViz, Friendly, [])


func HandleReserveSupply(Performer : BattleShipStats, Action : CardStats, Mod : ReserveModule) -> void:
	var resupplyamm = Mod.ReserveAmmount

	var Targets = await HandleTargets(Mod, Performer)
	var TargetViz : Array[Control]
	
	var Friendly = IsShipFriendly(Performer)
	
	for g in Targets:
		var TargetShip = GetTarget(g)
		if (TargetShip == null):
			continue
		TargetViz.append(GetShipViz(TargetShip))
		UpdateReserves(TargetShip, TargetShip.EnergyReserves + resupplyamm, TargetShip == Performer and Friendly)
			
	await DoDeffenceAnim(Action, Mod, Performer, TargetViz, Friendly, [])

func HandleReserveConversion(Performer : BattleShipStats, Action : CardStats, Mod : ReserveConversionModule) -> void:
	var resupplyamm = Mod.GetConversionAmmount(Performer.EnergyReserves)
	
	var Friendly = IsShipFriendly(Performer)
	
	UpdateReserves(Performer, 0, Friendly)

	#var Targets = await HandleTargets(Mod, Performer)
	#var TargetViz : Array[Control]

	UpdateEnergy(Performer, Performer.Energy + resupplyamm, Friendly)
			
	await DoDeffenceAnim(Action, Mod, Performer, [GetShipViz(Performer)], Friendly, [])

func HandleMaxReserveSupply(Performer : BattleShipStats, Action : CardStats, Mod : MaxReserveModule) -> void:
	var resupplyamm = Performer.Energy

	var Targets = await HandleTargets(Mod, Performer)
	var TargetViz : Array[Control]
	
	var Friendly = IsShipFriendly(Performer)
	
	for g in Targets:
		var TargetShip = GetTarget(g)
		if (TargetShip == null):
			continue
		TargetViz.append(GetShipViz(TargetShip))
		UpdateReserves(TargetShip, TargetShip.EnergyReserves + resupplyamm, TargetShip == Performer and Friendly)
	
	UpdateEnergy(Performer, 0, Friendly)
			
	await DoDeffenceAnim(Action, Mod, Performer, TargetViz, Friendly, [])

func HandleFireExtinguish(Performer : BattleShipStats, Action : CardStats, Mod : CardModule) -> void:
	var viz = GetShipViz(Performer)

	await DoDeffenceAnim(Action, Mod, Performer, [viz], IsShipFriendly(Performer), [viz.ToggleFire.bind(false)])
	
	
func HandleSelfDamage(Performer : BattleShipStats, Action : CardStats, Mod : SelfDamageModule) -> void:

	var Callables : Array[Callable]
	Callables.append(DamageShip.bind(Performer, Mod.Damage * Action.Tier))
	
	await DoOffenceAnim(Action, Mod, [Performer], EnemyCombatants.has(Performer), Callables)


func HandleRecoil(Performer : BattleShipStats, Action : CardStats, DamageAmm : float, Mod : RecoilDamageModule) -> void:
	var Callables : Array[Callable]
	var Recoil = Mod.GetRecoilAmmount(DamageAmm)
	Callables.append(DamageShip.bind(Performer, Recoil))
	
	await DoOffenceAnim(Action, Mod, [Performer], EnemyCombatants.has(Performer), Callables)


func HandleShield(Performer : BattleShipStats, Action : CardStats, Mod : ShieldCardModule) -> void:
	#var viz = GetShipViz(Performer)

	var Targets = await HandleTargets(Mod, Performer)
	var TargetViz : Array[Control]
	
	var Callables : Array[Callable]
	
	for g in Targets:
		var TargetShip = GetTarget(g)
		if (TargetShip == null):
			continue
		TargetViz.append(GetShipViz(TargetShip))
		Callables.append(ShieldShip.bind(TargetShip, Mod.ShieldAmm * Action.Tier))
	
	await DoDeffenceAnim(Action, Mod, Performer, TargetViz, IsShipFriendly(Performer), Callables)

func HandleMaxShield(Performer : BattleShipStats, Action : CardStats, Mod : MaxShieldCardModule) -> void:
	var ShieldAmm = Performer.Energy * Mod.ShieldPerEnergy
	
	var Targets = await HandleTargets(Mod, Performer)
	var TargetViz : Array[Control]
	
	var Callables : Array[Callable]
	
	for g in Targets:
		var TargetShip = GetTarget(g)
		if (TargetShip == null):
			continue
		TargetViz.append(GetShipViz(TargetShip))
		Callables.append(ShieldShip.bind(TargetShip, ShieldAmm * Action.Tier))
	
	var Friendly = IsShipFriendly(Performer)
	
	UpdateEnergy(Performer, 0, Friendly)
	
	await DoDeffenceAnim(Action, Mod, Performer, TargetViz, Friendly, Callables)

func HandleCauseFire(Performer : BattleShipStats, Action : CardStats, Mod : CauseFireModule) -> void:
	#var viz = GetShipViz(Performer)
	
	var Targets = await HandleTargets(Mod, Performer)
	var TargetViz : Array[Control]
	
	var Callables : Array[Callable]
	
	for g in Targets:
		var TargetShip = GetTarget(g)
		if (TargetShip == null):
			continue
		TargetViz.append(GetShipViz(TargetShip))
		Callables.append(ToggleFireToShip.bind(TargetShip, true))
		
	await DoDeffenceAnim(Action, Mod, Performer, TargetViz, EnemyCombatants.has(Performer), Callables)


func HandleDamageStack(Performer : BattleShipStats, Action : CardStats, Mod : StackDamageCardModule) -> void:
	var OffensiveModule = Action.OnPerformModule.duplicate() as OffensiveCardModule
	var NewAction = Action.duplicate()
	NewAction.OnPerformModule = OffensiveModule
	Action = NewAction
	OffensiveModule.Damage += OffensiveModule.Damage * Mod.BuffAmmount
	
	await DoDeffenceAnim(Action, Mod, Performer, [], EnemyCombatants.has(Performer), [])

func HandleBuff(Performer : BattleShipStats, Action : CardStats, Mod : BuffModule) -> void:
	var Targets = await HandleTargets(Mod, Performer)
	var TargetViz : Array[Control]
	
	var Callables : Array[Callable]
	
	for g in Targets:
		var TargetShip = GetTarget(g)
		if (TargetShip == null):
			continue
		TargetViz.append(GetShipViz(TargetShip))
		
		if (Mod.StatToBuff == CardModule.Stat.FIREPOWER):
			Callables.append(BuffShip.bind(TargetShip, Mod.BuffAmmount, Mod.BuffDuration))
		else : if (Mod.StatToBuff == CardModule.Stat.SPEED):
			Callables.append(BuffShipSpeed.bind(TargetShip, Mod.BuffAmmount, Mod.BuffDuration))
		else : if (Mod.StatToBuff == CardModule.Stat.DEFENCE):
			Callables.append(DeBuffShipDefence.bind(TargetShip, Mod.BuffAmmount, Mod.BuffDuration))
			
	await DoDeffenceAnim(Action, Mod, Performer, TargetViz, EnemyCombatants.has(Performer), Callables)


func HandleDeBuff(Performer : BattleShipStats, Action : CardStats, Mod : CardModule) -> void:
	var Targets = await HandleTargets(Mod, Performer)
	var TargetViz : Array[Control]
	
	var Callables : Array[Callable]
	
	for g in Targets:
		var TargetShip = GetTarget(g)
		if (TargetShip == null):
			continue
		TargetViz.append(GetShipViz(TargetShip))

		if (Mod.StatToDeBuff == CardModule.Stat.FIREPOWER):
			Callables.append(DeBuffShipSpeed.bind(TargetShip, Mod.DeBuffAmmount, Mod.DeBuffDuration))
		else : if (Mod.StatToDeBuff == CardModule.Stat.SPEED):
			Callables.append(DeBuffShipSpeed.bind(TargetShip, Mod.DeBuffAmmount, Mod.DeBuffDuration))
		else : if (Mod.StatToDeBuff == CardModule.Stat.DEFENCE):
			Callables.append(DeBuffShipDefence.bind(TargetShip, Mod.DeBuffAmmount, Mod.DeBuffDuration))
			
	await DoDeffenceAnim(Action, Mod, Performer, TargetViz, EnemyCombatants.has(Performer), Callables)

func GetTargetIndex(Target : BattleShipStats) -> int:
	var Index : int
	if (IsShipFriendly(Target)):
		Index = PlayerCombatants.find(Target)
	else:
		Index = EnemyCombatants.find(Target) + 3
	
	return Index

func GetTarget(Index : int) -> BattleShipStats:
	var Target : BattleShipStats
	if (Index > 2):
		if Index - 3 > EnemyCombatants.size() - 1 :
			return null
		Target = EnemyCombatants[Index - 3]
	else:
		if Index > PlayerCombatants.size() - 1 :
			return null
		Target = PlayerCombatants[Index]
	return Target

func HandleTargets(Mod : CardModule, User : BattleShipStats) -> Array[int]:
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.CARD_FIGHT_TARGET_PICKING)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.CARD_FIGHT_TARGET_PICKING)
		ActionTracker.GetInstance().ShowTutorial("Target Picking", "Some cards require you to pick a target, weather that is a friendly or enemy depends on the card.\nOther cards can be multi target, meaning they instantly target the whole team, or self use meaning they are used by the performer. Those cards will be used instantly without asking for a target.", [], true)
	
	var Friendly = IsShipFriendly(User)
	
	var Targets : Array[int]
	# we handle deffensive target picking a bit differently
	if (Mod is DeffenceCardModule):
		#If aoe pick all team either if enemy of player
		if (Mod.AOE):
			var Team = GetShipsTeam(User)
			for g in Team:
				Targets.append(GetTargetIndex(g))
			if (!Mod.SelfUse):
				Targets.erase(GetTargetIndex(User))
		#If can be used on others prompt player to choose, or if enemy pick randomly
		else: if Mod.CanBeUsedOnOther:
			if (Friendly):
				var PossibleTargets = PlayerCombatants
				if (!Mod.SelfUse):
					PossibleTargets.erase(User)
				TargetSelect.SetEnemies(PossibleTargets)
				SelectingTarget = true
				var Target = await TargetSelect.EnemySelected
				if (Target != null):
					Targets.append(GetTargetIndex(Target))
				SelectingTarget = false
			else:
				Targets.append(GetTargetIndex(EnemyCombatants.pick_random()))
		#if nothing of the above counts pick the user as the target
		else:
			Targets = [GetTargetIndex(User)]
	else:
		var EnemyTeam = GetShipEnemyTeam(User)
		#If aoe pick all enemy team either if enemy of player
		if (Mod.AOE):
			for g in EnemyTeam:
				Targets.append(GetTargetIndex(g))

		#If there is only 1 
		else: if EnemyTeam.size() == 1:
			Targets.append(GetTargetIndex(EnemyTeam[0]))
		else:
			if (Friendly):
				TargetSelect.SetEnemies(EnemyCombatants)
				SelectingTarget = true
				var Target = await TargetSelect.EnemySelected
				if (Target != null):
					Targets.append(GetTargetIndex(Target))
				SelectingTarget = false
			else:
				Targets.append(GetTargetIndex(PlayerCombatants.pick_random()))
	
	return Targets


func HandleDrawCard(Performer : BattleShipStats) -> bool:
	if (Shuffling):
		return false
	
	var D = GetShipDeck(Performer)
	
	if (D.DeckPile.size() <= 0):
		await HandleShuffleDiscardedIntoDeck(D)
	
	var C = D.DeckPile.pop_front()
	
	var c = CardScene.instantiate() as Card
	c.SetCardBattleStats(Performer, C)
	#c.connect("OnCardPressed", OnCardSelected)
	
	DeckP.OnCardDrawn()
	
	var Placed = await PlaceCardInPlayerHand(Performer, c)
	
	if (!Placed):
		c.queue_free()
		return true
		#call_deferred("DoCardPlecementAnimation", c, ExternalUI.GetDeckkPile().global_position)
	
	return true


func HandleDrawCardEnemy(Performer : BattleShipStats) -> void:
	var D = EnemyDecks[Performer]
	
	if (D.DeckPile.size() <= 0):
		HandleShuffleDiscardedIntoDeck(D, false)
	
	var C = D.DeckPile.pop_front()
	
	PlaceCardInEnemyHand(Performer, C)


func HandleDrawSpecificCard(Performer : BattleShipStats, Spawn : CardStats) -> void:
	
	var D = GetShipDeck(Performer)
	
	if (D.DeckPile.size() <= 0):
			await HandleShuffleDiscardedIntoDeck(D)
			
	var HasCardInDeck : bool = false
	
	for g : CardStats in D.DeckPile:
		if (g.CardName == Spawn.CardName):
			HasCardInDeck = true
			break
	
	if (!HasCardInDeck):
		await HandleShuffleDiscardedIntoDeck(D)
	
	var c = CardScene.instantiate() as Card
	c.SetCardBattleStats(Performer, Spawn)
	#c.connect("OnCardPressed", OnCardSelected)
	
	DeckP.OnCardDrawn()
	
	D.DeckPile.erase(Spawn)
	
	var Placed = await PlaceCardInPlayerHand(Performer, c)
	
	if (Placed):
		pass
		#call_deferred("DoCardPlecementAnimation", c, ExternalUI.GetDeckkPile().global_position)
	else:
		c.queue_free()

func HandleMultiDrawSpecific(Performer : BattleShipStats, Action : CardStats, Mod : MultiCardSpawnModule) -> void:
	
	var D = GetShipDeck(Performer)
	
	if (D.DeckPile.size() <= 0):
			await HandleShuffleDiscardedIntoDeck(D)
			
	var PossibleCards : Array[CardStats]
	
	for g : CardStats in D.DeckPile:
		if (Mod.TestCard(g.OnPerformModule)):
			if (!PossibleCards.has(g)):
				PossibleCards.append(g)
			continue
		for m in g.OnUseModules:
			if (Mod.TestCard(m)):
				if (!PossibleCards.has(g)):
					PossibleCards.append(g)
				break
	
	CardSelect.SetCardsPick(Performer, PossibleCards)
	
	SelectingTarget = true
	var Picked = await CardSelect.CardSelected
	SelectingTarget = false
	
	var c = CardScene.instantiate() as Card
	c.SetCardBattleStats(Performer, PossibleCards[Picked])

	DeckP.OnCardDrawn()
	
	D.DeckPile.erase(PossibleCards[Picked])
	
	var Placed = await PlaceCardInPlayerHand(Performer, c)
	
	if (Placed):
		pass
		#call_deferred("DoCardPlecementAnimation", c, ExternalUI.GetDeckkPile().global_position)
	else:
		c.queue_free()

func HandleMultiDrawSpecificEnemy(Performer : BattleShipStats, Action : CardStats, Mod : MultiCardSpawnModule) -> void:
	
	var D = GetShipDeck(Performer)
	
	if (D.DeckPile.size() <= 0):
			await HandleShuffleDiscardedIntoDeck(D)
	
	var PossibleCards : Array[CardStats]
	
	for g : CardStats in D.DeckPile:
		if (Mod.TestCard(g.OnPerformModule)):
			PossibleCards.append(g)
			continue
		for m in g.OnUseModules:
			if (Mod.TestCard(m)):
				PossibleCards.append(g)
				break
	
	var Picked = PossibleCards.pick_random()

	D.DeckPile.erase(Picked)
	
	PlaceCardInEnemyHand(Performer, Picked)

func HandleDrawSpecificCardEnemy(Performer : BattleShipStats,Spawn : CardStats) -> void:
	var D = EnemyDecks[GetCurrentShip()]
	
	if (D.DeckPile.size() <= 0):
			await HandleShuffleDiscardedIntoDeck(D)
	
	var HasCardInDeck : bool = false
	
	var C : CardStats
	
	for g : CardStats in D.DeckPile:
		if (g.CardName == Spawn.CardName):
			HasCardInDeck = true
			C = g
			break
	
	if (!HasCardInDeck):
			HandleShuffleDiscardedIntoDeck(D, false)
	
	D.DeckPile.erase(Spawn)
	
	PlaceCardInEnemyHand(Performer ,C)


var Shuffling : bool = false

func HandleShuffleDiscardedIntoDeck(D : Deck, DoAnim : bool = true) -> void:
	Shuffling = true
	
	if (DoAnim):
		for g in D.DiscardPile.size():
			await Helper.GetInstance().wait(0.05)
			DiscardP.OnCardRemoved()
			DeckP.OnCardAdded(DiscardP.global_position)
			if (g == D.DiscardPile.size() - 1):
				await DeckP.CardAddFinished
				
	D.DeckPile.append_array(D.DiscardPile)
	D.DiscardPile.clear()
	
	D.DeckPile.shuffle()
	
	Shuffling = false

#//////////////////////////////////////////////////////////////////////
#██   ██ ████   ██ ██ ████  ████ ██   ██    ██    ██ ██    ██ ████   ██ 
#███████ ██ ██  ██ ██ ██ ████ ██ ███████    ██    ██ ██    ██ ██ ██  ██ 
#██   ██ ██  ██ ██ ██ ██  ██  ██ ██   ██    ██    ██ ██    ██ ██  ██ ██ 
#██   ██ ██   ████ ██ ██      ██ ██   ██    ██    ██  ██████  ██   ████
#//////////////////////////////////////////////////////////////////////

func DoDeffenceAnim(Action : CardStats, Mod : CardModule, Performer : BattleShipStats, TargetViz : Array[Control], _FriendShip : bool, ToCallOnContact : Array[Callable]) -> void:
	#print("Starting Def Anim")
	var anim = ActionAnim.instantiate() as CardOffensiveAnimation
	AnimationPlecement.add_child(anim)
	AnimationPlecement.move_child(anim, 1)
	anim.DoDeffensive(Action, Mod, Performer, TargetViz, _FriendShip)
	
	for g in ToCallOnContact:
		await anim.DeffenceConnected
		g.call()
	#print("Deffence Connected")
	
	await(anim.AnimationFinished)
	#print("Animation Finished")
	anim.visible = false
	anim.queue_free()


func DoOffenceAnim(Action : CardStats, Mod : CardModule, Targets : Array[BattleShipStats], _FriendShip : bool, ToCallOnContact : Array[Callable]) -> void:
	var anim = ActionAnim.instantiate() as CardOffensiveAnimation
	AnimationPlecement.add_child(anim)
	AnimationPlecement.move_child(anim, 1)
	
	var targs : Dictionary[BattleShipStats, Dictionary]
	for g in Targets:
		targs[g] = {
			"Def" : null,
			"Viz" : GetShipViz(g)
		}
		
	anim.DoOffensive(Action, Mod, targs, GetCurrentShip(), _FriendShip)
	
	
	for g in ToCallOnContact:
		await anim.AtackConnected
		g.call()
	
	await(anim.AnimationFinished)


func DoCardSelectAnimation(Action : CardStats, Performer : BattleShipStats, User : Control) -> void:
	var anim = ActionAnim.instantiate() as CardOffensiveAnimation
	AnimationPlecement.add_child(anim)
	AnimationPlecement.move_child(anim, 1)
	anim.DoSelection(Action, Performer, User)
	
	var S = DeletableSoundGlobal.new()
	S.stream = CardPlecementSound
	S.autoplay = true
	S.pitch_scale = randf_range(0.8, 1.2)
	#S.bus = "MapSounds"
	add_child(S)
	S.volume_db = - 20
	
	await(anim.AnimationFinished)


func DoCardPlecementAnimation(User : BattleShipStats, C : Card, OriginalPos : Vector2) -> void:
	var c = CardScene.instantiate() as Card
	
	c.SetCardBattleStats(User, C.CStats)
	#c.TargetLocs = C.TargetLocs
	$SubViewport/Control2.add_child(c)
	c.global_position = OriginalPos
	#c.CompactCard()
	#C.CompactCard()
	var S = DeletableSoundGlobal.new()
	S.stream = CardPlecementSound
	S.autoplay = true
	S.pitch_scale = randf_range(0.8, 1.2)
	#S.bus = "MapSounds"
	add_child(S)
	S.volume_db = - 20
	var PlecementTw = create_tween()
	#var RotationTw = create_tween()
	PlecementTw.set_ease(Tween.EASE_OUT)
	PlecementTw.set_trans(Tween.TRANS_QUAD)
	#RotationTw.set_ease(Tween.EASE_OUT)
	#RotationTw.set_trans(Tween.TRANS_QUAD)
	var pos = C.global_position
	PlecementTw.tween_property(c, "global_position", C.global_position, 0.4)
	#.tween_property(c, "rotation", C.rotation, 0.4)
	var parent = C.get_parent()
	parent.remove_child(C)
	
	#C.visible = false
	await PlecementTw.finished
	c.queue_free()
	
	parent.add_child(C)
	C.global_position = pos
	#if (C != null):
		#C.visible = true


func DoCardAnim(OriginalPos : Vector2, Target : Control) -> void:
	var c = CardThing.instantiate() as CardViz
	c.Target = Target
	AnimationPlecement.add_child(c)
	c.global_position = OriginalPos

#
#////////////////////////////////////////////////////////////////////////////
 #██████  ███████ ████████ ████████ ███████ ██████  ███████ 
#██       ██         ██       ██    ██      ██   ██ ██      
#██   ███ █████      ██       ██    █████   ██████  ███████ 
#██    ██ ██         ██       ██    ██      ██   ██      ██ 
 #██████  ███████    ██       ██    ███████ ██   ██ ███████ 
#////////////////////////////////////////////////////////////////////////////
#Usefull getters

func GetCurrentShip() -> BattleShipStats:
	return ShipTurns[CurrentTurn]

func GetShipsTeam(Ship : BattleShipStats) -> Array[BattleShipStats]:
	var Team : Array[BattleShipStats]
	if (IsShipFriendly(Ship)):
		Team.append_array(PlayerCombatants)
	else:
		Team.append_array(EnemyCombatants)
	return Team


func GetShipEnemyTeam(Ship : BattleShipStats) -> Array[BattleShipStats]:
	var Team : Array[BattleShipStats]
	if (IsShipFriendly(Ship)):
		Team.append_array(EnemyCombatants)
	else:
		Team.append_array(PlayerCombatants)
	return Team


func GetShipsTeamViz(Ship : BattleShipStats) -> Array[Control]:
	var Team : Array[Control]
	if (IsShipFriendly(Ship)):
		for g in PlayerCombatants:
			Team.append(GetShipViz(g))
	else:
		for g in EnemyCombatants:
			Team.append(GetShipViz(g))
	return Team


func GetShipDeck(Ship : BattleShipStats) -> Deck:
	if (IsShipFriendly(Ship)):
		return PlayerDecks[Ship]
	return EnemyDecks[Ship]


func GetShipViz(BattleS : BattleShipStats) -> CardFightShipViz2:
	return ShipsViz[BattleS]


func GetFightingUnitAmmount(Ships : Array[BattleShipStats]) -> int:
	var CombatantAmmount = 0
	for g in Ships:
		if (!g.Convoy):
			CombatantAmmount += 1
	return CombatantAmmount


func IsShipFriendly(Ship : BattleShipStats) -> bool:
	return PlayerCombatants.has(Ship) or PlayerReserves.has(Ship)


#////////////////////////////////////////////////////////////////////////////
#███████ ████████  █████  ████████     ███    ███  █████  ███    ██ ██ ██████  ██    ██ ██       █████  ████████ ██  ██████  ███    ██ 
#██         ██    ██   ██    ██        ████  ████ ██   ██ ████   ██ ██ ██   ██ ██    ██ ██      ██   ██    ██    ██ ██    ██ ████   ██ 
#███████    ██    ███████    ██        ██ ████ ██ ███████ ██ ██  ██ ██ ██████  ██    ██ ██      ███████    ██    ██ ██    ██ ██ ██  ██ 
	 #██    ██    ██   ██    ██        ██  ██  ██ ██   ██ ██  ██ ██ ██ ██      ██    ██ ██      ██   ██    ██    ██ ██    ██ ██  ██ ██ 
#███████    ██    ██   ██    ██        ██      ██ ██   ██ ██   ████ ██ ██       ██████  ███████ ██   ██    ██    ██  ██████  ██   ████ 
#////////////////////////////////////////////////////////////////////////////

# RETURNΣ TRUE IF FIGHT IS OVER
func DamageShip(Ship : BattleShipStats, Amm : float, CauseFire : bool = false, SkipShield : bool = false) -> bool:
	var Dmg = Amm - (Amm * Ship.GetDef())
	if (!SkipShield):
		if Ship.Shield > 0:
			var origshield = Ship.Shield
			Ship.Shield = max(0,origshield - Amm)
			Dmg -= origshield - Ship.Shield
	Ship.CurrentHull -= Dmg

	if (CauseFire or TrySetFire()):
		ToggleFireToShip(Ship, true)
	
	if (IsShipFriendly(Ship)):
		
		if (Ship.CurrentHull < 40 and !ActionTracker.IsActionCompleted(ActionTracker.Action.CARD_FIGHT_SHIPLOSS)):
			ActionTracker.OnActionCompleted(ActionTracker.Action.CARD_FIGHT_SHIPLOSS)
			ActionTracker.GetInstance().ShowTutorial("Lossing Ships", "When a ships hull reaches zero, they are threwn out of the fight and the capmaign. Make use of the 'Switch Ship' button to switch up ships in the fight. The ship that gets switched in loses one turn.", [], true)
	
		DamageGot += Dmg
		if (Dmg > 0):
			UIEventH.OnControlledShipDamaged(Dmg)
	else:
		DamageDone += Dmg
	
	if (Ship.CurrentHull <= 0):
		if (ShipDestroyed(Ship)):
			return true
		#else:
			#CheckForReserves()
	else:
		UpdateShipStats(Ship)
	return false


func ShieldShip(Ship : BattleShipStats, Amm : float) -> void:
	Ship.Shield = Ship.Shield + Amm
	UpdateShipStats(Ship)


func BuffShip(Ship : BattleShipStats, Amm : float, Turns : int = 2) -> void:
	#buffs are usually 1.2 or 1.3 so we keep the 0.2 and add it
	Ship.FirePowerBuff += Amm - 1
	Ship.FirePowerBuffTime = Turns
	
	UpdateShipStats(Ship)


func DeBuffShip(Ship : BattleShipStats, Amm : float, Turns : int = 2) -> void:
	#buffs are usually 1.2 or 1.3 so we keep the 0.2 and add it
	Ship.FirePowerDeBuff += Amm - 1
	Ship.FirePowerDeBuffTime = Turns
	
	UpdateShipStats(Ship)


func BuffShipSpeed(Ship : BattleShipStats, Amm : float, Turns : int = 2) -> void:
	Ship.SpeedBuff += Amm - 1
	Ship.SpeedBuffTime = Turns
	
	UpdateShipStats(Ship)


func DeBuffShipSpeed(Ship : BattleShipStats, Amm : float, Turns : int = 2) -> void:
	#buffs are usually 1.2 or 1.3 so we keep the 0.2 and add it
	Ship.SpeedDeBuff += Amm
	Ship.SpeedDeBuffTime = Turns
	
	UpdateShipStats(Ship)

func DeBuffShipDefence(Ship : BattleShipStats, Amm : float, Turns : int = 2) -> void:
	#buffs are usually 1.2 or 1.3 so we keep the 0.2 and add it
	Ship.DefDebuff += Amm
	Ship.DefDeBuffTime = Turns
	
	UpdateShipStats(Ship)

# RETURN TRUE IF FIGHT IS OVER
func ShipDestroyed(Ship : BattleShipStats) -> bool:
	
	if (EnemyCombatants.has(Ship)):
		FundsToWin += Ship.Funds
	
	ReplaceShip(Ship)
	#RemoveShip(Ship)
	
	var EnemiesDead = GetFightingUnitAmmount(EnemyCombatants) == 0 and GetFightingUnitAmmount(EnemyReserves) == 0
	var PlayerDead = GetFightingUnitAmmount(PlayerCombatants) == 0 and GetFightingUnitAmmount(PlayerReserves) == 0
	
	if (EnemiesDead or PlayerDead):
		
		GameOver = true
		call_deferred("OnFightEnded", EnemiesDead)
		return true
		
	return false


func TrySetFire() -> bool:
	randomize()
	var random_value = randf()
	return random_value < 0.2

#atm of a ship is on fire is stored in the UI. Should change #TODO
func ToggleFireToShip(BattleS : BattleShipStats, Fire : bool) -> void:
	GetShipViz(BattleS).ToggleFire(Fire)


func RemoveShip(Ship : BattleShipStats) -> void:
	var ShipViz = GetShipViz(Ship)
	ShipViz.ShipDestroyed()
	ShipsViz.erase(Ship)
	
	ActionList.RemoveShip(Ship)

	ShipTurns.erase(Ship)
	PlayerCombatants.erase(Ship)
	EnemyCombatants.erase(Ship)
#////////////////////////////////////////////////////////////////////////////
#██    ██ ██ 
#██    ██ ██ 
#██    ██ ██ 
#██    ██ ██ 
 #██████  ██ 
#////////////////////////////////////////////////////////////////////////////
func UpdateHandCards() -> void:
	
	ExternalUI.ClearHand()
	
	var CurrentShip = GetCurrentShip()
	var CharDeck = GetShipDeck(CurrentShip)
	
	for ran in CharDeck.Hand:
		var c = CardScene.instantiate() as Card
		
		c.SetCardBattleStats(CurrentShip, ran)
		#c.connect("OnCardPressed", OnCardSelected)
		
		ExternalUI.AddCardToHand(c)
		#call_deferred("DoCardPlecementAnimation", c, ExternalUI.GetDeckkPile().global_position)
	
	UpdateHandAmount(CharDeck.Hand.size())


func UpdateCardDescriptions(User : BattleShipStats):
	ExternalUI.UpdateCardDesc(User)
	for g : Card in SelectedCardPlecement.get_children():
		g.UpdateBattleStats(User)


func UpdateShipStats(BattleS : BattleShipStats) -> void:
	var Friendly = IsShipFriendly(BattleS)
	var viz = GetShipViz(BattleS)
	viz.UpdateStats(BattleS)
	viz.ToggleDmgBuff(BattleS.FirePowerBuff > 1, BattleS.FirePowerBuff)
	viz.ToggleSpeedBuff(BattleS.SpeedBuff > 1, BattleS.SpeedBuff)
	viz.ToggleDefBuff(BattleS.DefBuff > 0, BattleS.DefBuff)
	
	viz.ToggleDmgDebuff(BattleS.FirePowerDeBuff > 0)
	viz.ToggleSpeedDebuff(BattleS.SpeedDeBuff > 0)
	viz.ToggleDefDeBuff(BattleS.DefDebuff > 0)
	if (ShipTurns.find(BattleS) == CurrentTurn):
		UpdateCardDescriptions(BattleS)


func UpdateEnergy(Ship : BattleShipStats, NewEnergy : float, UpdateUI : bool) -> void:
	var OldEnergy = Ship.Energy
	
	Ship.Energy = NewEnergy
	if (UpdateUI):
		ExternalUI.GetEnergyBar().UpdateAmmount(OldEnergy, NewEnergy)
		if (NewEnergy > ExternalUI.GetEnergyBar().GetSegmentAmm()):
			ExternalUI.GetEnergyBar().ChangeSegmentAmm(Ship.Energy)
	
	UpdateCardDescriptions(Ship)

func UpdateReserves(Ship : BattleShipStats, NewEnergy : float, UpdateUI : bool) -> void:
	var OldEnergy = Ship.EnergyReserves
	
	Ship.EnergyReserves = NewEnergy
	if (UpdateUI):
		ExternalUI.GetReserveBar().UpdateAmmount(OldEnergy, NewEnergy)
		if (NewEnergy > ExternalUI.GetReserveBar().GetSegmentAmm()):
			ExternalUI.GetReserveBar().ChangeSegmentAmm(Ship.EnergyReserves)
	
	UpdateCardDescriptions(Ship)

func UpdateHandAmount(NewAmm : int) -> void:
	HandAmmountLabel.text = "In Hand {0}/{1}".format([NewAmm, MaxCardsInHand])


func UpdateFleetSizeAmmount() -> void:
	PlayerFleetSizeLabel.text = "Fleet Size\n{0}".format([PlayerReserves.size() + PlayerCombatants.size()])
	EnemyFleetSizeLabel.text = "Fleet Size\n{0}".format([EnemyReserves.size() + EnemyCombatants.size()])
	

func ClearCards() -> void:
	ExternalUI.ClearHand()
	for g in SelectedCardPlecement.get_children():
		g.free()

var HandCountTween : Tween

func NotifyFullHand() -> void:
	if (HandCountTween and HandCountTween.is_running()):
		HandCountTween.kill()
	
	HandCountTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).set_parallel(true)
	HandCountTween.tween_property(HandAmmountLabel,"scale", Vector2(1.2, 1.2), 0.55)
	
	HandCountTween.finished.connect(NotifyFullHandStage2)
	
func NotifyFullHandStage2() -> void:
	HandCountTween.kill()
	
	HandCountTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel(true)
	HandCountTween.tween_property(HandAmmountLabel,"scale", Vector2.ONE, 0.55)


func _on_deck_button_pressed() -> void:
	var Ship = GetCurrentShip()

	var Energy = Ship.Energy
	
	if (SelectingTarget or Energy < 1 or EnemyPickingMove):
		ExternalUI.GetEnergyBar().NotifyNotEnough()
		ExternalUI.CardDrawFail()
		return
	
	if (await HandleDrawCard(Ship)):
		UpdateEnergy(Ship, Energy - 1, true)


func _on_pull_reserves_pressed() -> void:
	var currentship = GetCurrentShip()
	var Reserv = currentship.EnergyReserves
	currentship.EnergyReserves = 0
	UpdateEnergy(currentship, currentship.Energy + Reserv, true)
	UpdateReserves(currentship, 0, true)
	

func _on_switch_ship_pressed() -> void:
	if (SelectingTarget or !PickingMoves or EnemyPickingMove or PlayerPerformingMove or CurrentPhase != CardFightPhase.ACTION_PICK):
		return
	var CurrentShip = GetCurrentShip()

	TargetSelect.SetEnemies(PlayerReserves, true)
	SelectingTarget = true
	var NewCombatant = await TargetSelect.EnemySelected
	SelectingTarget = false
	
	if (NewCombatant == null):
		return
	
	var ShipViz = GetShipViz(CurrentShip)
	await ShipViz.ShipDestroyed()
	
	ShipViz.get_parent().remove_child(ShipViz)
	add_child(ShipViz)
	
	ShipsViz.erase(CurrentShip)
	
	PlayerCombatants.erase(CurrentShip)
	PlayerReserves.append(CurrentShip)
	
	ActionList.RemoveShip(CurrentShip)
	
	PlayerCombatants.append(NewCombatant)
	PlayerReserves.erase(NewCombatant)
	
	var Spot = ShipTurns.find(CurrentShip)
	ShipTurns.remove_at(Spot)
	ShipTurns.insert(Spot, NewCombatant)
	#ShipTurns.sort_custom(speed_comparator)
	CreateShipVisuals(NewCombatant, true)
	#CreateDecks()
	
	PlayerActionSelectionEnded()

#////////////////////////////////////////////////////////////////////////////

func PlaceCardInPlayerHand(Performer : BattleShipStats,C : Card) -> bool:
	var CanPlace : bool = false
	
	#var CardsInHand : int = PlayerCardPlecement.get_child_count()
	var PlDeck = GetShipDeck(Performer)

	if (PlDeck.Hand.size() < MaxCardsInHand):
		CanPlace = true
			
	#print("{0} removed from {1}'s deck".format([C.CStats.CardName, Performer.Name]))
	#PlDeck.DeckPile.erase(C.CStats)
	
	if (CanPlace):
		print("{0} added to {1}'s hand".format([C.CStats.CardName, Performer.Name]))
		PlDeck.Hand.append(C.CStats)
		ExternalUI.OnCardDrawn(C)

	else:
		ExternalUI.ToggleHandInput(false)
		
		var Hand : Array[Card]
		Hand = ExternalUI.GetCardsInHand()
		#for g in SelectedCardPlecement.get_children():
			#if (g.get_child_count() > 0):
				#Hand.append(g.get_child(0))
		
		Hand.append(C)
		
		CardSelect.SetCards(Performer, Hand)
		SelectingTarget = true
		if (!ActionTracker.IsActionCompleted(ActionTracker.Action.CARD_FIGHT_HAND_LIMIT)):
			ActionTracker.OnActionCompleted(ActionTracker.Action.CARD_FIGHT_HAND_LIMIT)
			ActionTracker.GetInstance().ShowTutorial("Hand Limit", "At any time you can hold a max of {0} cards in your hand. If at any point an extra hand is about to be placed in your hand, you will be asked to choose one card to throw out. Picked card is placed on the discard pile.".format([MaxCardsInHand]), [], true)
		
		var ToDiscard : int = await CardSelect.CardSelected
		SelectingTarget = false

		if (ToDiscard == MaxCardsInHand):
			print("{0} has been added to {1}'s discard pile.".format([C.CStats.CardName, Performer.Name]))
			PlDeck.DiscardPile.append(C.CStats)
			DiscardP.OnCardDiscarded(DeckP.global_position)
			ExternalUI.ToggleHandInput(true)
			return false
		
		PlDeck.Hand.append(C.CStats)
		
		#var Plecement = PlayerCardPlecement.get_child(ToDiscard)
		var Discarded : Card = ExternalUI.GetPlayerCardPlecement().get_child(ToDiscard)
		await ExternalUI.InsertCardToDiscard(Discarded)
		print("{0} has been added to {1}'s discard pile.".format([Discarded.CStats.CardName, Performer.Name]))
		PlDeck.DiscardPile.append(Discarded.CStats)
		DiscardP.OnCardDiscarded(Discarded.global_position + (Discarded.size / 2))
		Discarded.get_parent().queue_free()
		ExternalUI.OnCardDrawn(C)
		PlDeck.Hand.erase(Discarded.CStats)
		
		ExternalUI.ToggleHandInput(true)
	
	UpdateHandAmount(PlDeck.Hand.size())
	return true


func PlaceCardInEnemyHand(Performer : BattleShipStats, C : CardStats) -> bool:
	var CanPlace : bool = false
	
	var EnemyDeck = EnemyDecks[Performer]
	
	var CardsInHand : int = EnemyDeck.Hand.size()

	if (CardsInHand < MaxCardsInHand):
		CanPlace = true

	#EnemyDeck.DeckPile.erase(C)
	
	if (CanPlace):
		EnemyDeck.Hand.append(C)
	else:
		EnemyDeck.Hand.append(C)
		var ToDiscard = EnemyDeck.Hand.pick_random()
		EnemyDeck.Hand.erase(ToDiscard)
		print("{0} has been added to {1}'s discard pile.".format([ToDiscard.CardName, Performer.Name]))
		EnemyDeck.DiscardPile.append(ToDiscard)

	return true

#////////////////////////////////////////////////////////////////////////////////////////////////
#██████   █████  ███    ██ ██████   ██████  ███    ███     ███████ ██  ██████  ██   ██ ████████ 
#██   ██ ██   ██ ████   ██ ██   ██ ██    ██ ████  ████     ██      ██ ██       ██   ██    ██    
#██████  ███████ ██ ██  ██ ██   ██ ██    ██ ██ ████ ██     █████   ██ ██   ███ ███████    ██    
#██   ██ ██   ██ ██  ██ ██ ██   ██ ██    ██ ██  ██  ██     ██      ██ ██    ██ ██   ██    ██    
#██   ██ ██   ██ ██   ████ ██████   ██████  ██      ██     ██      ██  ██████  ██   ██    ██    
#////////////////////////////////////////////////////////////////////////////////////////////////
func InitRandomFight(ShipAmm : int) -> void:
	for g in ShipAmm:
		EnemyReserves.append(load(GetRandomCaptain(true)).GetBattleStats())

	for g in ShipAmm:
		PlayerReserves.append(load(GetRandomCaptain(false)).GetBattleStats())

func GenerateRandomisedShip(Name : String, enemy : bool) -> BattleShipStats:
	var Stats = BattleShipStats.new()
	Stats.Name = Name
	Stats.FirePower = randf_range(0.5, 3)
	Stats.Hull = randf_range(10, 800)
	Stats.Speed = randf_range(0.5, 3)

	Stats.ShipIcon = load(GetRandomShipIcon())
		
	if (!enemy):
		Stats.CaptainIcon = load("res://Assets/CaptainPortraits/Captain1.png")
	else:
		Stats.CaptainIcon = load("res://Assets/CaptainPortraits/Captain9.png")
	#
	Stats.Cards[load("res://Resources/Cards/Barrage/Barrage.tres")] = 8
	Stats.Cards[load("res://Resources/Cards/Evasive.tres")] = 4
	Stats.Cards[load("res://Resources/Cards/Missile/Missile.tres")] = 10
	Stats.Cards[load("res://Resources/Cards/Flares.tres")] = 3
	Stats.Cards[load("res://Resources/Cards/ShieldOverChargeTeam.tres")] = 2
	Stats.Cards[load("res://Resources/Cards/RadarBuff.tres")] = 1
	Stats.Cards[load("res://Resources/Cards/RadarBuffSingle.tres")] = 2
	Stats.Cards[load("res://Resources/Cards/SpeedBuff.tres")] = 2
	Stats.Cards[load("res://Resources/Cards/Barrage/DrawRandomBarrage.tres")] = 3
	Stats.Cards[load("res://Resources/Cards/Extringuish.tres")] = 4
	Stats.Cards[load("res://Resources/Cards/Energy.tres")] = 4
	Stats.Cards[load("res://Resources/Cards/EnergyReserve.tres")] = 3
	Stats.Cards[load("res://Resources/Cards/DrawDiscard.tres")] = 2
	
	Stats.Cards[load("res://Resources/Cards/Barrage/APBarrage.tres")] = 2
	Stats.Cards[load("res://Resources/Cards/Barrage/IncendiaryBarrage.tres")] = 2
	Stats.Cards[load("res://Resources/Cards/Barrage/ProxFuseBarrage.tres")] = 2
	Stats.Cards[load("res://Resources/Cards/Missile/ClusterMissile.tres")] = 2
	
		
	return Stats

func GetRandomCaptain(Enemy : bool) -> String:
	var Cpts
	if (!Enemy):
		Cpts = ["res://Resources/Captains/PlayerCaptains/Craden.tres", "res://Resources/Captains/PlayerCaptains/Amol.tres", "res://Resources/Captains/PlayerCaptains/Baron.tres", "res://Resources/Captains/PlayerCaptains/Corkan.tres", "res://Resources/Captains/PlayerCaptains/Dimitry.tres", "res://Resources/Captains/PlayerCaptains/Elena.tres", "res://Resources/Captains/PlayerCaptains/Gilian.tres", "res://Resources/Captains/PlayerCaptains/Jor.tres"]
	else:
		Cpts = ["res://Resources/Captains/EnemyCaptains/EnemyFireship1.tres", "res://Resources/Captains/EnemyCaptains/EnemyFireship2.tres", "res://Resources/Captains/EnemyCaptains/EnemyFireship3.tres", "res://Resources/Captains/EnemyCaptains/EnemyFireship4.tres", "res://Resources/Captains/EnemyCaptains/EnemyMissileCarrier1.tres", "res://Resources/Captains/EnemyCaptains/EnemyMissileCarrier2.tres", "res://Resources/Captains/EnemyCaptains/EnemyMissileCarrier3.tres", "res://Resources/Captains/EnemyCaptains/EnemyMissileCarrier4.tres", "res://Resources/Captains/EnemyCaptains/EnemyRadarShip1.tres", "res://Resources/Captains/EnemyCaptains/EnemyRadarShip2.tres", "res://Resources/Captains/EnemyCaptains/EnemyRadarShip3.tres", "res://Resources/Captains/EnemyCaptains/EnemyRadarShip4.tres", "res://Resources/Captains/EnemyCaptains/EnemyTanker1.tres", "res://Resources/Captains/EnemyCaptains/EnemyTanker2.tres", "res://Resources/Captains/EnemyCaptains/EnemyTanker3.tres", "res://Resources/Captains/EnemyCaptains/EnemyTanker4.tres", "res://Resources/Captains/EnemyCaptains/LandEnemyFireship1.tres", "res://Resources/Captains/EnemyCaptains/LandEnemyFireship2.tres"]
	return Cpts.pick_random()
	
func GetRandomShipIcon() -> String:
	var Icons = ["res://Assets/Spaceship/Spaceship_top_2_Main Camera.png", "res://Assets/Spaceship/Spaceship_top_Main Camera.png", "res://Assets/Spaceship/Tanker2.png", "res://Assets/Spaceship/Tanker.png", "res://Assets/Spaceship/Convoy.png", "res://Assets/Spaceship/Scarab.png", "res://Assets/Spaceship/Ship3_001.png", "res://Assets/Spaceship/Ship4_001.png", "res://Assets/Spaceship/ShipElena2.png", "res://Assets/Spaceship/ShipElena.png"]
	return Icons.pick_random()

#////////////////////////////////////////////////////////////////////////////////////////////////

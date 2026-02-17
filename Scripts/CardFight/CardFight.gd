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
@export_file var ShipVizScene : String
@export var DamageFloater : PackedScene
#Animation of the atack
@export_file("*.tscn") var ActionAnimFile : String
#Scene that shows the stats of the fight
@export_file("*.tscn") var EndSceneFile : String
@export_file("*.tscn") var ShipInfoSceneFile : String

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
@export var Cloud : ColorRect
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

var FightLoc : Vector2

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
var PlayerCasualties : Array[BattleShipStats]

var EnemyReserves : Array[BattleShipStats]
var EnemyCombatants : Array[BattleShipStats]
var EnemyCasualties : Array[BattleShipStats]

#Decks holding info about cards in hand/discard pile/deck pile
var PlayerDecks : Dictionary[BattleShipStats, Deck]
var EnemyDecks : Dictionary[BattleShipStats, Deck]

#List of all UI for each ship combatants, they are created once a ship is added from reserves to combatants
#var ShipsViz : Dictionary[BattleShipStats, CardFightShipViz2]

#Once a ship pickes a move its saved here and this list is used to perform the action on the action perform phase
var ActionList = CardFightActionList.new()


var SelectingTarget : bool = false
var EnemyPickingMove : bool = false
var PlayerPerformingMove : bool = false
var PickingMoves : bool = false
var CurrentPhase : CardFightPhase

var ShipBeingReplaced : Array[CardFightShipViz2]
signal ShipReplecementFinished

enum CardFightPhase{
	ACTION_PICK,
	ACTION_PERFORM,
}

signal CardFightEnded(Survivors : Array[BattleShipStats], won : bool)
signal CardFightDestroyed()

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
		var NewCombatant = EnemyReserves.pop_front()
		EnemyCombatants.append(NewCombatant)
		EnemyReserves.erase(NewCombatant)
		CreateShipVisuals(NewCombatant, false)
	var PlReservesAmm : int = PlayerReserves.size()
	for g in min(MaxCombatants, PlReservesAmm):
		var NewCombatant = PlayerReserves.pop_front()
		PlayerCombatants.append(NewCombatant)
		PlayerReserves.erase(NewCombatant)
		CreateShipVisuals(NewCombatant, true)
	#Add all ships to turn array and sort them
	ShipTurns.append_array(PlayerCombatants)
	ShipTurns.append_array(EnemyCombatants)

	
	ShipTurns.sort_custom(speed_comparator)
	
	UpdateFleetSizeAmmount()
	#Create the visualisation for each ship, basicly their stat holder
	#ExternalUI.ToggleEnergyVisibility(false)
	ExternalUI.HideInfo()

	Helper.GetInstance().CallLater(StartFight, 2)
	
	var Mat = $SubViewport/Control2/Ground.material as ShaderMaterial
	Mat.set_shader_parameter("offset", Vector2(randf_range(-100, 100), randf_range(-100, 100)))


func _exit_tree() -> void:
	MusicManager.GetInstance().SwitchMusic(false)

var CloudOffset = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	CloudOffset += Vector2(-0.0001, 0.0001)
	Cloud.material.set_shader_parameter("Offset", CloudOffset)


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
	ActionList.RemoveShip(Ship)
	#Save the ships index in the turns array so that we can add this ship on same position
	var TurnPosition = ShipTurns.find(Ship)
	
	var Position = ShipTurns.find(Ship)
	if (CurrentTurn > Position):
		CurrentTurn -= 1
	ShipTurns.erase(Ship)
	
	var NewCombatant : BattleShipStats
	var Friendly = IsShipFriendly(Ship)
	
	if (Friendly):
		#save index so we can add any replacement on that position
		#var Index = PlayerCombatants.find(Ship)
		PlayerCombatants.erase(Ship)
		PlayerCasualties.append(Ship)
		if (PlayerReserves.size() > 0):
			NewCombatant = PlayerReserves.pop_front()
			PlayerCombatants.append(NewCombatant)
			PlayerReserves.erase(NewCombatant)
			
			ShipTurns.insert(TurnPosition, NewCombatant)
			#ShipTurns.sort_custom(speed_comparator)
		#else:
			#PlayerReserves.insert(Index, null)
	else:
		#save index so we can add any replacement on that position
		#var Index = EnemyCombatants.find(Ship)
		EnemyCombatants.erase(Ship)
		EnemyCasualties.append(Ship)
		
		if (EnemyReserves.size() > 0):
			NewCombatant = EnemyReserves.pop_front()
			EnemyCombatants.append(NewCombatant)
			EnemyReserves.erase(NewCombatant)
			
			ShipTurns.insert(TurnPosition, NewCombatant)

	var NewVisuals 
	if (NewCombatant != null):
		NewVisuals = CreateShipVisuals(NewCombatant, Friendly)
		NewVisuals.visible = false
	#Play the dead animation on the ShipViz
	
	var Viz = Ship.ShipViz
	
	ShipBeingReplaced.append(Viz)
	await Viz.Destroy()
	ShipReplecementFinished.emit()
	ShipBeingReplaced.erase(Viz)
	var Pos = Viz.global_position
	Viz.get_parent().remove_child(Viz)
	$SubViewport/Control2/DeadShipLoc.add_child(Viz)
	Viz.global_position = Pos
	NewTurnStarted.disconnect(Viz.OnNewTurnStarted)
	
	if (NewVisuals != null):
		NewVisuals.visible = true
			
	UpdateFleetSizeAmmount()


func CreateDecks() -> void:
	#Create the deck
	var Ships : Array[BattleShipStats]
	Ships.append_array(PlayerReserves)
	Ships.append_array(EnemyReserves)
	for g in Ships:
		var D = Deck.new()

		D.DeckPile.append_array(g.Cards)
		#Create Hand
		D.DeckPile.shuffle()
		for Hand in StartingCardAmm:
			var C = D.DeckPile.pop_front()
			if (C != null):
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


func ShipVizPressed(Ship : BattleShipStats) -> void:
	var CardFightShipInfoScene : PackedScene = ResourceLoader.load(ShipInfoSceneFile)
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
	if (GameOver):
		return
	ActionDeclaration.DoActionDeclaration("Action Pick Phase", 2)
	ActionDeclaration.ActionDeclarationFinished.connect(PickPhase)
	#await DoActionDeclaration("Action Pick Phase", 2)


func PickPhase() -> void:
	if (GameOver):
		return
	ActionDeclaration.ActionDeclarationFinished.disconnect(PickPhase)
	CurrentPhase = CardFightPhase.ACTION_PICK
	CurrentTurn = 0
	
	NewTurnStarted.emit()
	
	ProgressBuffsForCurrentShip()
	

func ProgressBuffsForCurrentShip() -> void:
	if (GameOver):
		return
	if (CurrentTurn < ShipTurns.size()):
		var CurrentShip = GetCurrentShip()
		var viz = CurrentShip.ShipViz
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
	if (GameOver):
		return
	CurrentTurn = 0
	
	ShipTurns.sort_custom(speed_comparator)
	
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.CARD_FIGHT_ACTION_PICK)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.CARD_FIGHT_ACTION_PICK)
		await ActionTracker.GetInstance().ShowTutorial("Action Picking Phase", "During the Action Picking Phase, each ship selects its moves for the upcoming Action Performing Phase. Ships with higher speed have the advantage of choosing and executing their moves first.\nRemember that every offensive action has a corresponding defensive option, so it’s crucial to protect your ship while maintaining a strong offensive stance.", [], true)

	CurrentPlayerLabel.visible = true
	
	StartCurrentShipsPickTurn()


func StartCurrentShipsPickTurn() -> void:
	if (GameOver):
		return
	if (CurrentTurn < ShipTurns.size()):
		var Ship = GetCurrentShip()
		CurrentPlayerLabel.text = "{0} picking".format([Ship.Name])
		ActionDeclaration.DoActionDeclaration(Ship.Name + "'s turn", 1.5)
		EnemyPickingMove = !IsShipFriendly(Ship)
		ActionDeclaration.ActionDeclarationFinished.connect(RunShipsTurn.bind(Ship))
	else:
		StartActionPerform()


func RunShipsTurn(Ship : BattleShipStats) -> void:
	if (GameOver):
		return
	ActionDeclaration.ActionDeclarationFinished.disconnect(RunShipsTurn)
	
	var viz = Ship.ShipViz
	var D = GetShipDeck(Ship)
	viz.Enable()
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.CARD_FIGHT_SPEED_EXPLENATION)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.CARD_FIGHT_SPEED_EXPLENATION)
		await ActionTracker.GetInstance().ShowTutorial("Ship Speed", "Each ships has a speed stat. Faster ships get to choose and also get to perform their moves first.", [viz], true)
	
	ActionList.AddShip(Ship)
	if (IsShipFriendly(Ship)):
		if (D.GetCardAmm() == 0):
			PopUpManager.GetInstance().DoFadeNotif("{0}'s deck is empty. Turn skipped".format([Ship.Name]))
			PlayerActionPickingEnded.emit()
			return
		#ExternalUI.ToggleEnergyVisibility(true)
		if (!ActionTracker.IsActionCompleted(ActionTracker.Action.CARD_FIGHT_ENERGY)):
			ActionTracker.OnActionCompleted(ActionTracker.Action.CARD_FIGHT_ENERGY)
			await ActionTracker.GetInstance().ShowTutorial("Energy", "Each card has a cost that needs to be payed in order to use it. \nEach ship starts their action picking phase with 10 energy to spare. \nAny unused energy is lost at the end of turn.", [Map.UI_ELEMENT.CARD_FIGHT_ENERGY_BAR], true)

		if (!ActionTracker.IsActionCompleted(ActionTracker.Action.CARD_FIGHT_RESERVES)):
			ActionTracker.OnActionCompleted(ActionTracker.Action.CARD_FIGHT_RESERVES)
			await ActionTracker.GetInstance().ShowTutorial("Energy Reserves", "Some cards can provide a ship with energy reserves. Energy reserves are kept until the player decides to use them and can be accumulated indefinetly. At any point the 'Pull Reserves' is pressed any amount of reserves kept on the ship will be lost and gained as energy to use on that turn.", [Map.UI_ELEMENT.CARD_FIGHT_RESERVE_BAR], true)
		
		RestartCards()
		
		PickingMoves = true
	else:
		if (D.GetCardAmm() == 0):
			PopUpManager.GetInstance().DoFadeNotif("{0}'s deck is empty. Turn skipped".format([Ship.Name]))
			EnemyActionPickedEnded.emit()
			return
		EnemyPickingMove = true
		await HandleDrawCardEnemy(Ship)
		EnemyActionSelection(Ship)
	
	


func OnCardSelected(C : Card) -> bool:
	if (SelectingTarget):
		PopUpManager.GetInstance().DoFadeNotif("Finish selecting target")
		return false
	if (EnemyPickingMove):
		PopUpManager.GetInstance().DoFadeNotif("Enemy is selecting their moves")
		return false
	if (Shuffling):
		PopUpManager.GetInstance().DoFadeNotif("Shuffling in progress")
		return false

	
	var Ship = GetCurrentShip()
	
	if (Ship.Energy < C.GetCost()):
		ExternalUI.GetEnergyBar().NotifyNotEnough()
		PopUpManager.GetInstance().DoFadeNotif("Not enough energy")
		return false
	
	
	
	PlayerPerformingMove = true
	
	var deck = GetShipDeck(Ship)
	
	UpdateEnergy(Ship, Ship.Energy - C.GetCost(), true)
	print("{0} has been removed from {1}'s hand.".format([C.CStats.GetCardName(), Ship.Name]))
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
				var TargetViz = g.ShipViz
				if (TargetViz == null):
					continue
				c.TargetLocs.append(TargetViz.GetShipPos())
			ShipAction.Targets.append_array(targets)
		
		
		c.SetCardBattleStats(Ship, Action)
		
		c.connect("OnCardPressed", RemoveCard)
		
		SelectedCardPlecement.add_child(c)

		Ship.ShipViz.ActionPicked(Action.Icon)
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
			print("{0} has been added to {1}'s discard pile.".format([C.CStats.GetCardName(), Ship.Name]))
			deck.DiscardPile.append(C.CStats)
			ExternalUI.DiscardPile.OnCardDiscarded(C.global_position + (C.size / 2))
	
	ExternalUI.UpdateCardsInHandAmm(deck.Hand.size(), MaxCardsInHand)
	
	if (C.CStats.Consume):
		for g in Ship.Cards:
			if (g.IsSame(C.CStats)):
				Ship.Cards.erase(g)
				break
				
	await HandleModules(Ship, C.CStats)
	
	
	PlayerPerformingMove = false

	return true


func RemoveCard(C : Card) -> void:
	if (SelectingTarget):
		PopUpManager.GetInstance().DoFadeNotif("Finish selecting target")
		return
	if (EnemyPickingMove):
		PopUpManager.GetInstance().DoFadeNotif("Enemy is selecting their moves")
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
		ShipCards.append(Stats)

	CurrentShip.ShipViz.ActionRemoved(Stats.Icon)
	ActionList.RemoveActionFromShip(CurrentShip, Stats)
	
	var PerformModule = Stats.OnPerformModule
	if (PerformModule is EnergyOffensiveCardModule):
		UpdateEnergy(CurrentShip, CurrentShip.Energy + PerformModule.StoredEnergy, true)
		PerformModule.StoredEnergy = 0
	else:
		UpdateEnergy(CurrentShip, CurrentShip.Energy + C.GetCost(), true)
	
	
	D.Hand.append(Stats)
	ExternalUI.UpdateCardsInHandAmm(D.Hand.size(), MaxCardsInHand)
	
	var c = CardScene.instantiate() as Card
	c.SetCardBattleStats(CurrentShip, Stats)
	
	ExternalUI.OnCardDrawn(c)
	
	C.queue_free()


func EnemyActionSelection(Ship : BattleShipStats) -> void:
	Ship.Energy = TurnEnergy + Ship.EnergyReserves
	Ship.EnergyReserves = 0
	
	var EnemyDeck = EnemyDecks[Ship]
	var TeamSize = EnemyCombatants.size()
	
	var FireExtinguishToUse : CardStats
	
	var AvailableActions = EnemyDeck.Hand.duplicate()
	var Actions = ""
	for g : CardStats in AvailableActions:
		Actions += g.GetCardName() + ", "
	print("{0}'s hand : {1}".format([Ship.Name, Actions]))
	
	var t = func CheckIfToDraw(Acts : Array[CardStats]) -> Array[CardStats]:
		if (Acts.size() == 0 and Ship.Energy > 0 and EnemyDeck.Hand.size() < MaxCardsInHand):
			print("{0} draws a card".format([Ship.Name]))
			Ship.Energy -= 1
			await HandleDrawCardEnemy(Ship)
			Acts.clear()
			return EnemyDeck.Hand.duplicate()
		return Acts
		
	while (AvailableActions.size() > 0):
		var Action = (AvailableActions.pick_random() as CardStats)
		
		print("{0} tries to player card {1}".format([Ship.Name, Action.GetCardName()]))
		
		if (!Action.AllowDuplicates and ActionList.ShipHasAction(Ship, Action)):
			AvailableActions.erase(Action)
			AvailableActions = await t.call(AvailableActions)

		else: if (Action.Energy > Ship.Energy):
			print("{0} cant use {1}, not enough energy".format([Ship.Name, Action.GetCardName()]))
			AvailableActions.erase(Action)
			AvailableActions = await t.call(AvailableActions)
			
		else : if (Action.CardName == "Extinguish fires" and !Ship.IsOnFire):
			print("{0} cant use {1}, not on fire".format([Ship.Name, Action.GetCardName()]))
			AvailableActions.erase(Action)
			AvailableActions = await t.call(AvailableActions)
			
		else : if (Action.CardName == "Extinguish fires" and Ship.IsOnFire):
			Ship.Energy -= Action.Energy
			FireExtinguishToUse = Action
			EnemyDeck.Hand.erase(Action)
			print("{0} has been added to {1}'s discard pile.".format([Action.GetCardName(), Ship.Name]))
			EnemyDeck.DiscardPile.append(Action)
			AvailableActions.erase(Action)
			AvailableActions = await t.call(AvailableActions)
			
		else: if (Action.UseConditions.has(CardStats.CardUseCondition.NO_SOLO) and TeamSize == 1):
			print("{0} cant use {1}, team too small".format([Ship.Name, Action.GetCardName()]))
			AvailableActions.erase(Action)
			AvailableActions = await t.call(AvailableActions)
			
		else : if (Action.UseConditions.has(CardStats.CardUseCondition.ENERGY_DEPENDANT) and Ship.Energy == 0):
			print("{0} cant use {1}, card is scales with energy and ship has none".format([Ship.Name, Action.GetCardName()]))
			AvailableActions.erase(Action)
			AvailableActions = await t.call(AvailableActions)
		
		else : if (Action.UseConditions.has(CardStats.CardUseCondition.RESERVE_DEPENDANT) and Ship.EnergyReserves == 0):
			print("{0} cant use {1}, card is scales with reserve and ship has none".format([Ship.Name, Action.GetCardName()]))
			AvailableActions.erase(Action)
			AvailableActions = await t.call(AvailableActions)
		
		else : if (Action.UseConditions.has(CardStats.CardUseCondition.ENOUGH_TURNS_PASSED) and CurrentTurn > ShipTurns.size() / 2.0):
			print("{0} cant use {1}, not enought turns passed".format([Ship.Name, Action.GetCardName()]))
			AvailableActions.erase(Action)
			AvailableActions = await t.call(AvailableActions)
			
		else : if (Action.UseConditions.has(CardStats.CardUseCondition.HAS_DEBUFF) and !Ship.HasDebuff()):
			print("{0} cant use {1}, card is cleansing debuffs and ship has none".format([Ship.Name, Action.GetCardName()]))
			AvailableActions.erase(Action)
			AvailableActions = await t.call(AvailableActions)
		else : if (Action.UseConditions.has(CardStats.CardUseCondition.ENOUGH_HP) and (Ship.CurrentHull / Ship.Hull) * 100 < 10):
			print("{0} cant use {1}, it's hull is too low.".format([Ship.Name, Action.GetCardName()]))
			AvailableActions.erase(Action)
			AvailableActions = await t.call(AvailableActions)
		else : if (Action.UseConditions.has(CardStats.CardUseCondition.ENOUGH_DEF) and Ship.GetDef() <= 0):
			print("{0} cant use {1}, it's defense is too low.".format([Ship.Name, Action.GetCardName()]))
			AvailableActions.erase(Action)
			AvailableActions = await t.call(AvailableActions)
		#else : if (Action.UseConditions.has(CardStats.CardUseCondition.ENOUGH_FP) and Ship.GetFirePower() <= 0):
			#print("{0} cant use {1}, it's hull is too low.".format([Ship.Name, Action.GetCardName()]))
			#AvailableActions.erase(Action)
			#AvailableActions = await t.call(AvailableActions)
		#else : if (Action.UseConditions.has(CardStats.CardUseCondition.ENOUGHT_SPEED) and Ship.GetSpeed() <= 0):
			#print("{0} cant use {1}, it's hull is too low.".format([Ship.Name, Action.GetCardName()]))
			#AvailableActions.erase(Action)
			#AvailableActions = await t.call(AvailableActions)
		else:
			print("{0} uses {1}".format([Ship.Name, Action.GetCardName()]))
			var SelectedAction : CardStats = Action.duplicate()
			
			Ship.Energy -= SelectedAction.Energy
			
			EnemyDeck.Hand.erase(Action)
			#EnemyDeck.DiscardPile.append(Action)
			AvailableActions.erase(Action)

			
			await HandleModules(Ship, SelectedAction)
			
			if (SelectedAction.OnPerformModule == null):
				print("{0} has been added to {1}'s discard pile.".format([SelectedAction.GetCardName(), Ship.Name]))
				EnemyDeck.DiscardPile.append(SelectedAction)
			else:
				if (SelectedAction.OnPerformModule is EnergyOffensiveCardModule):
					var NewMod = SelectedAction.OnPerformModule.duplicate()
					NewMod.StoredEnergy = Ship.Energy
					UpdateEnergy(Ship, 0, false)
					SelectedAction.OnPerformModule = NewMod
					
				await DoCardSelectAnimation(SelectedAction, Ship, Ship.ShipViz)
				
				var ShipAction = CardFightAction.new()
				ShipAction.Action = SelectedAction

				ShipAction.Targets = await HandleTargets(Action.OnPerformModule, Ship)
				Ship.ShipViz.ActionPicked(SelectedAction.Icon)
				ActionList.AddAction(Ship, ShipAction)

			AvailableActions = await t.call(AvailableActions)
	
	if (FireExtinguishToUse != null):
		await HandleModules(Ship, FireExtinguishToUse)
		
	print("{0} ended their turn with {1} exess energy".format([Ship.Name, Ship.Energy]))
	EnemyActionPickedEnded.emit()
	

func PlayerActionSelectionEnded() -> void:
	if (SelectingTarget):
		PopUpManager.GetInstance().DoFadeNotif("Finish selecting target")
		return
	if (EnemyPickingMove):
		PopUpManager.GetInstance().DoFadeNotif("Enemy is selecting their moves")
		return
	if (CurrentPhase != CardFightPhase.ACTION_PICK):
		PopUpManager.GetInstance().DoFadeNotif("Can't perform outside of Action Pick phase")
		return
	if (!PickingMoves):
		return
	#GetShipViz(ShipTurns[CurrentTurn]).Dissable()
	PlayerActionPickingEnded.emit()


func CurrentEnemyTurnEnded() -> void:
	var Ship = GetCurrentShip()
	var viz = Ship.ShipViz
	viz.Dissable()
	viz.OnActionsPerformed()
	EnemyPickingMove = false
	CurrentTurn = CurrentTurn + 1
	StartCurrentShipsPickTurn()


func CurrentPlayerTurnEnded() -> void:
	PickingMoves = false
	ClearCards()

	ExternalUI.HideInfo()
	var Ship = GetCurrentShip()
	var viz = Ship.ShipViz
	viz.Dissable()
	viz.OnActionsPerformed()
	
	CurrentTurn = CurrentTurn + 1
	
	StartCurrentShipsPickTurn()


func StartActionPerform() -> void:
	
	CurrentPlayerLabel.visible = false
	ClearCards()
	
	#Sort ships again to make sure speed buffs are taken into account
	ShipTurns.sort_custom(speed_comparator)

	ExternalUI.HideInfo()
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
	
	await DoCurrentShipFireDamage()


func DoCurrentShipFireDamage() -> void:
	if (CurrentTurn < ShipTurns.size()):
		var CurrentShip = GetCurrentShip()

		var viz = CurrentShip.ShipViz
		if (CurrentShip.IsOnFire):
			
			var d = DamageFloater.instantiate() as Floater
			if (CurrentShip.IsSeverelyBurnt()):
				d.text = "Severe\nFire Damage"
			else:
				d.text = "Fire Damage"
			d.modulate = Color(1,0,0,1)
			viz.add_child(d)
			d.global_position = (viz.global_position + (viz.size / 2)) - d.size / 2
			d.Ended.connect(DoCurrentShipFireDamage)
			var GameEnded = await DamageShip(CurrentShip, CurrentShip.GetFireDamage(), false, true)
			
			CurrentShip.TurnsOnFire += 1
			
			if (GameEnded):
				return
			
			CurrentTurn = CurrentTurn + 1

			return
		
		else:
			CurrentTurn = CurrentTurn + 1
			await DoCurrentShipFireDamage()
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
	await Ship.ShipViz.Pop(true)
	#viz.Enable()
	PerformNextActionForShip(Ship, 0)

func PerformNextActionForShip(Ship : BattleShipStats, ActionIndex : int) -> void:
	if (GameOver):
		return
		
	var Dec = GetShipDeck(Ship)
	var Friendly = IsShipFriendly(Ship)
	
	var ShipActions = ActionList.GetShipsActions(Ship)
	
	if (ShipActions.size() - 1 < ActionIndex):
		PerformTurnFinished(Ship)
		return
	
	var ShipAction = ShipActions[ActionIndex] as CardFightAction
	var Action = ShipAction.Action

	var Targets = ShipAction.Targets
	
	var TargetShips : Array[BattleShipStats]
	
	for g in Targets:
		if (g != null and ShipTurns.has(g)):
			TargetShips.append(g)
	
	if (TargetShips.size() == 0):
		ActionIndex += 1
		PerformNextActionForShip(Ship, ActionIndex)
	else:
		var Mod = Action.OnPerformModule

		if (Mod is OffensiveCardModule):
			ActionList.RemoveActionFromShip(Ship, Action)
			var Counter : CardStats
			var AtackType = Mod.AtackType


			#List containing targets and a bool saying if target has def
			var TargetList : Dictionary[BattleShipStats, Dictionary]
			
			for g in TargetShips:

				for Act : CardFightAction in ActionList.GetShipsActions(g):
					var mod = Act.Action.OnPerformModule
					if (mod is CounterCardModule or mod is DamageReductionCardModule):
						if (mod.CounterType == AtackType or mod.CounterType == OffensiveCardModule.AtackTypes.ANY_ATACK):
							Counter = Act.Action
							break
					
				var Data : Dictionary
				Data["Def"] = Counter
				Data["Viz"] = g.ShipViz
				TargetList[g] = Data

			Ship.ShipViz.ActionRemoved(Action.Icon)
			
			var AtackData = OffensiveAnimationData.new()
			
			AtackData.Mod = Mod
			AtackData.DeffenceList = TargetList
			
			var AnimData : Array[AnimationData]
			AnimData.append(AtackData)
			
			var DamageCallables : Array[Callable]
			
			var AtackConnected = false
			
			for g in TargetList:
				
				var Def = TargetList[g]["Def"] as CardStats
				
				if (TargetList[g]["Def"] != null):
					
					var TargetViz = TargetList[g]["Viz"]
					TargetViz.ActionRemoved(Counter.Icon)
					ActionList.RemoveActionFromShip(g, Counter)
					if (!Counter.ShouldConsume()):
						var TargetDeck = GetShipDeck(g)
						print("{0} has been added to {1}'s discard pile.".format([Counter.GetCardName(), g.Name]))
						TargetDeck.DiscardPile.append(Counter)
							
					if (!Friendly):
						DamageNeg += Mod.GetFinalDamage(Ship, Action.Tier)
						
					var CounterMod = Def.OnPerformModule
					
					if (CounterMod is DamageReductionCardModule):
						var c = Callable.create(self, "DamageShip").bind(g, Mod.GetFinalDamage(Ship,Action.Tier) * CounterMod.GetReductionPercent(Def.Tier), Mod.CauseFile, Mod.SkipShield)
						DamageCallables.append(c)
						for SDefMod in CounterMod.OnSuccesfullDeffenceModules:
							AnimData.append(await HandleModule(Ship, Def, SDefMod))
						AtackConnected = true
						
					if (CounterMod is CounterCardModule):
						for SDefMod in CounterMod.OnSuccesfullDeffenceModules:
							AnimData.append(await HandleModule(Ship, Def, SDefMod))
				else:
					AtackConnected = true
				
				if (AtackConnected):
					for SAtMod in Mod.OnSuccesfullAtackModules:
						AnimData.append(await HandleModule(Ship, Action, SAtMod, TargetList.keys()))
						
					var c = Callable.create(self, "DamageShip").bind(g, Mod.GetFinalDamage(Ship,Action.Tier), Mod.CauseFile, Mod.SkipShield)
					DamageCallables.append(c)
			
			for SAtMod in Mod.OnAtackModules:
				AnimData.append(await HandleModule(Ship, Action, SAtMod, TargetList.keys()))

			AtackData.Callables = DamageCallables
			
			if (!Action.ShouldConsume()):
				print("{0} has been added to {1}'s discard pile.".format([Action.GetCardName(), Ship.Name]))
				Dec.DiscardPile.append(Action)
			
			await DoCardAnim(Action, AnimData, Ship, Friendly)
			PerformAnimationFinished(Ship, ActionIndex)
		else:
			ActionIndex += 1
			PerformNextActionForShip(Ship, ActionIndex)

func ConnectMoves(C : Array[Callable]) -> void:
	var c = C.pop_front() as Callable
	c.call()
	

func PerformAnimationFinished(Ship : BattleShipStats, ActionIndex : int) -> void:
	PerformNextActionForShip(Ship, ActionIndex)


func PerformTurnFinished(Ship : BattleShipStats) -> void:
	var ReplacingAmm = ShipBeingReplaced.size()
	for g in ReplacingAmm:
		await ShipReplecementFinished
		
	if (Ship != null):
		await Ship.ShipViz.Pop(false)
	CurrentTurn = CurrentTurn + 1
	StartCurrentShipsPerformTurn()


#Refunds cards that consume inventory items if the card wasnt used in the end
func RefundUnusedCards() -> void:
	for Ship in PlayerCombatants:
		var Acts = ActionList.GetShipsActions(Ship)
		for z in Acts:
			var ShipAction = z as CardFightAction
			#if (!ShipAction.Action.ShouldConsume()):
				#continue
			RefundCardToShip(ShipAction.Action, Ship)
			Ship.ShipViz.ActionRemoved(ShipAction.Action.Icon)
	for Ship in EnemyCombatants:
		if (Ship == null):
			continue
		var Acts = ActionList.GetShipsActions(Ship)
		for z in Acts:
			var ShipAction = z as CardFightAction
			#if (!ShipAction.Action.ShouldConsume()):
				#continue
			RefundCardToShip(ShipAction.Action, Ship)
			Ship.ShipViz.ActionRemoved(ShipAction.Action.Icon)


func RefundCardToShip(C : CardStats, Ship : BattleShipStats):
	print("{0} got refunded a {1} card for not using it.".format([Ship.Name, C.GetCardName()]))
	var deck = GetShipDeck(Ship)
	print("{0} has been added to {1}'s discard pile.".format([C.GetCardName(), Ship.Name]))
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
	
	ExternalUI.DiscardPile.UpdateDiscardPileAmmount(D.DiscardPile.size())
	ExternalUI.DeckUI.UpdateDeckPileAmmount(D.DeckPile.size())
	#GetShipViz(ShipTurns[CurrentTurn]).Enable()
	
	HandleDrawCard(currentship)

# CALLED AT THE END. SHOWS ENDSCREEN WITH DATA COLLECTED AND WAITS FOR PLAYER 
func OnFightEnded(Won : bool) -> void:
	var EndScene : PackedScene = ResourceLoader.load(EndSceneFile)
	var End = EndScene.instantiate() as CardFightEndScene
	var FrCombatants : Array[BattleShipStats]
	FrCombatants.append_array(PlayerCombatants)
	FrCombatants.append_array(PlayerReserves)
	FrCombatants.append_array(PlayerCasualties)
	
	var EnCombatants : Array[BattleShipStats]
	EnCombatants.append_array(EnemyCombatants)
	EnCombatants.append_array(EnemyReserves)
	EnCombatants.append_array(EnemyCasualties)
	
	var Data = BattleReportData.new()
	Data.SetData(Won, Clock.GetDateTimeString(), FundsToWin, DamageDone, DamageGot, DamageNeg, FrCombatants, EnCombatants, PlayerCasualties, EnemyCasualties, FightLoc)
	
	End.SetData(Data)
	add_child(End)

	
	var Survivors : Array[BattleShipStats]
	RefundUnusedCards()
	for g in PlayerCombatants:
		Survivors.append(g)
	for g in PlayerReserves:
		Survivors.append(g)
	for g in EnemyCombatants:
		Survivors.append(g)
	for g in EnemyReserves:
		Survivors.append(g)
	
	for g in Survivors:
		g.Cards.clear()
		var D = GetShipDeck(g)
		g.Cards = D.GetCardList()
	
	var won = EnemyCombatants.size() + EnemyReserves.size() < PlayerCombatants.size() + PlayerReserves.size()
	CardFightEnded.emit(Survivors, won)
	
	ExternalUI.TogglePlayerCardPlacement(false)
	
	await End.ContinuePressed
	
	CardFightDestroyed.emit()
	#queue_free()
	
	
#/////////////////////////////////////////////////////////////////////
#██   ██  █████  ███    ██ ██████  ██      ███████ ██████  ███████ 
#██   ██ ██   ██ ████   ██ ██   ██ ██      ██      ██   ██ ██      
#███████ ███████ ██ ██  ██ ██   ██ ██      █████   ██████  ███████ 
#██   ██ ██   ██ ██  ██ ██ ██   ██ ██      ██      ██   ██      ██ 
#██   ██ ██   ██ ██   ████ ██████  ███████ ███████ ██   ██ ███████ 
#/////////////////////////////////////////////////////////////////////

func HandleModules(Performer : BattleShipStats, C : CardStats, Targets : Array[BattleShipStats] = []) -> void:
	var AnimData : Array[AnimationData]
	for Mod in C.OnUseModules.size():
		var Data : AnimationData
		
		Data = await HandleModule(Performer, C ,C.OnUseModules[Mod], Targets)
		
		if (Mod < C.OnUseModules.size() - 1):
			await Helper.GetInstance().wait(0.2)
			
		if (Data != null):
			AnimData.append(Data)
			
	if (AnimData.size() > 0):
		await DoCardAnim(C, AnimData, Performer, true)


func HandleModule(Performer : BattleShipStats, C : CardStats, Mod : CardModule, Targets : Array[BattleShipStats] = []) -> AnimationData:
	var AnimData :AnimationData
	if (Mod is ResupplyModule):
		AnimData = await HandleResupply(Performer, C, Mod, Targets)
		
	else :if (Mod is CauseFireModule):
		AnimData = await HandleCauseFire(Performer, C, Mod, Targets)
		
	else : if (Mod is ReserveModule):
		AnimData = await HandleReserveSupply(Performer, C, Mod, Targets)
		
	else : if (Mod is ReserveConversionModule):
		AnimData = HandleReserveConversion(Performer, C, Mod, Targets)
		
	else : if (Mod is MaxReserveModule):
		AnimData = await HandleMaxReserveSupply(Performer, C, Mod, Targets)
		
	else : if (Mod is DrawCardModule):
		if (IsShipFriendly(Performer)):
			HandleDrawDriscard(Performer,C , Mod)
		else:
			HandleDrawDiscardEnemy(Performer, C, Mod)
	else : if (Mod is CardSpawnModule):
		var CardToSpawn = Mod.CardToSpawn.duplicate() as CardStats
		CardToSpawn.Tier = C.Tier
		if (IsShipFriendly(Performer)):
			HandleDrawSpecificCard(Performer, CardToSpawn)
		else:
			HandleDrawSpecificCardEnemy(Performer, CardToSpawn)
		
		
	else : if (Mod is MultiCardSpawnModule):
		if (IsShipFriendly(Performer)):
			HandleMultiDrawSpecific(Performer, Mod)
		else:
			HandleMultiDrawSpecificEnemy(Performer, Mod)
			
	else: if (Mod is FireExtinguishModule):
		AnimData = HandleFireExtinguish(Performer, C, Mod)
		
	else : if (Mod is BuffModule):
		AnimData = await HandleBuff(Performer, C, Mod, Targets)
		
	else : if (Mod is DeBuffEnemyModule or Mod is DeBuffSelfModule):
		AnimData = await HandleDeBuff(Performer, C, Mod, Targets)
	
	else : if (Mod is LoseBuffSelfModule):
		AnimData = await HandleBuffStrip(Performer, Mod)
	
	else : if (Mod is ShieldCardModule):
		AnimData = await HandleShield(Performer, C, Mod, Targets)
		
	else : if (Mod is MaxShieldCardModule):
		AnimData = await HandleMaxShield(Performer, C, Mod, Targets)
	else : if (Mod is SelfDamageModule):
		AnimData = HandleSelfDamage(Performer, C, Mod)
	else : if (Mod is RecoilDamageModule):
		var AtackMod = C.OnPerformModule as OffensiveCardModule
		AnimData = HandleRecoil(Performer, C, AtackMod.GetFinalDamage(Performer, C.Tier), Mod)
	else : if (Mod is StackDamageCardModule):
		AnimData = HandleDamageStack(Performer, C, Mod)
	else : if (Mod is CleanseDebuffModule):
		AnimData = await HandleDebuffCleanse(Performer, Mod)
	else : if (Mod is InterceptModule):
		AnimData = HandleIntercept(Performer, Mod)
	return AnimData


	
func HandleDrawDriscard(Performer : BattleShipStats, Action : CardStats, Mod : DrawCardModule) -> void:
	var D = GetShipDeck(Performer)
			
	var DrawAmmount = Mod.GetDrawAmmount(Action.Tier)
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
		
		ExternalUI.DeckUI.OnCardDrawn()
		CardsToDraw.append(c)
	
	while CardsToDiscard.size() < DiscardAmmount:
		CardSelect.SetCards(Performer, CardsToDraw)
		SelectingTarget = true
		var ToDiscard : int = await CardSelect.CardSelected
		SelectingTarget = false
		var Ca = CardsToDraw[ToDiscard]
		CardsToDraw.erase(Ca)
		CardsToDiscard.append(Ca)
		print("{0} has been added to {1}'s discard pile.".format([Ca.CStats.GetCardName(), Performer.Name]))
		D.DiscardPile.append(Ca.CStats)
		ExternalUI.DeckUI.OnCardDrawn()
		ExternalUI.DiscardPile.OnCardDiscarded(ExternalUI.DeckUI.global_position)
	
	for g in CardsToDraw:
		
		var Placed = await PlaceCardInPlayerHand(Performer, g)
		await Helper.GetInstance().wait(0.2)
		ExternalUI.DeckUI.OnCardDrawn()
		
		if (Placed):
			pass
			#call_deferred("DoCardPlecementAnimation", g, DeckP.global_position)
		else:
			g.queue_free()


func HandleDrawDiscardEnemy(Performer : BattleShipStats, Action : CardStats,Mod : DrawCardModule) -> void:
	var D = EnemyDecks[Performer]
				
	var DrawAmmount = Mod.GetDrawAmmount(Action.Tier)
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
		print("{0} has been added to {1}'s discard pile.".format([ToDiscard.GetCardName(), Performer.Name]))
		D.DiscardPile.append(ToDiscard)
	
	for g in CardsToDraw:
		PlaceCardInEnemyHand(Performer, g)

func HandleIntercept(Performer : BattleShipStats, Mod : InterceptModule) -> DeffensiveAnimationData:
	var TargetViz : Array[Control]
	TargetViz.append(Performer.ShipViz)
	
	for g in GetShipEnemyTeam(Performer):
		var Actions = ActionList.GetShipsActions(g)
		for Act : CardFightAction in Actions:
			if (Act.Targets.size() == 1 and !Act.Targets.has(Performer)):
				Act.Targets.clear()
				Act.Targets.append(Performer)
		
	
	var Data = DeffensiveAnimationData.new()
	Data.Mod = Mod
	Data.Targets = TargetViz
	return Data

func HandleResupply(Performer : BattleShipStats, Action : CardStats, Mod : ResupplyModule, TargetOverride : Array[BattleShipStats] = []) -> DeffensiveAnimationData:
	var resupplyamm = Mod.GetEnergyAmmount(Action.Tier)
	
	var Targets : Array[BattleShipStats]
	if (TargetOverride.size() > 0):
		Targets = TargetOverride
	else:
		var Ts = await HandleTargets(Mod, Performer)
		for g in Ts:
			Targets.append(g)
	
	var TargetViz : Array[Control]
	
	var Friendly = IsShipFriendly(Performer)
	
	for g in Targets:
		if (g == null):
			continue
		TargetViz.append(g.ShipViz)

		UpdateEnergy(g, g.Energy + resupplyamm, g == Performer and Friendly)
	
	var Data = DeffensiveAnimationData.new()
	Data.Mod = Mod
	Data.Targets = TargetViz
	return Data
	

func HandleReserveSupply(Performer : BattleShipStats, Action : CardStats, Mod : ReserveModule, TargetOverride : Array[BattleShipStats] = []) -> DeffensiveAnimationData:
	var resupplyamm = Mod.GetEnergy(Action.Tier)
	
	var Targets : Array[BattleShipStats]
	if (TargetOverride.size() > 0):
		Targets = TargetOverride
	else:
		var Ts = await HandleTargets(Mod, Performer)
		for g in Ts:
			Targets.append(g)

	var TargetViz : Array[Control]
	
	var Friendly = IsShipFriendly(Performer)
	
	for g in Targets:
		if (g == null):
			continue
		TargetViz.append(g.ShipViz)
		UpdateReserves(g, g.EnergyReserves + resupplyamm, g == Performer and Friendly)
			
	var Data = DeffensiveAnimationData.new()
	Data.Mod = Mod
	Data.Targets = TargetViz
	return Data

func HandleReserveConversion(Performer : BattleShipStats, Action : CardStats, Mod : ReserveConversionModule, _TargetOverride : Array[BattleShipStats] = []) -> DeffensiveAnimationData:
	var resupplyamm = Mod.GetConversionAmmount(Performer.EnergyReserves, Action.Tier)
	
	var Friendly = IsShipFriendly(Performer)
	
	UpdateReserves(Performer, 0, Friendly)

	UpdateEnergy(Performer, Performer.Energy + resupplyamm, Friendly)
	var TargetViz : Array[Control]
	TargetViz.append(Performer.ShipViz)
	var Data = DeffensiveAnimationData.new()
	Data.Mod = Mod
	Data.Targets = TargetViz
	return Data

func HandleMaxReserveSupply(Performer : BattleShipStats, _Action : CardStats, Mod : MaxReserveModule, TargetOverride : Array[BattleShipStats] = []) -> DeffensiveAnimationData:
	var resupplyamm = Performer.Energy
	
	var Targets : Array[BattleShipStats]
	if (TargetOverride.size() > 0):
		Targets = TargetOverride
	else:
		var Ts = await HandleTargets(Mod, Performer)
		for g in Ts:
			Targets.append(g)
			
	var TargetViz : Array[Control]
	
	var Friendly = IsShipFriendly(Performer)
	
	for g in Targets:
		if (g == null):
			continue
		TargetViz.append(g.ShipViz)
		UpdateReserves(g, g.EnergyReserves + resupplyamm, g == Performer and Friendly)
	
	UpdateEnergy(Performer, 0, Friendly)
	
	var Data = DeffensiveAnimationData.new()
	Data.Mod = Mod
	Data.Targets = TargetViz
	return Data

func HandleFireExtinguish(Performer : BattleShipStats, _Action : CardStats, Mod : CardModule) -> DeffensiveAnimationData:
	
	var Callables : Array[Callable] = [CombustFire.bind(Performer)]
	
	var Data = DeffensiveAnimationData.new()
	Data.Mod = Mod
	Data.Targets.append(Performer.ShipViz)
	Data.Callables = Callables
	return Data
	
	
func HandleSelfDamage(Performer : BattleShipStats, Action : CardStats, Mod : SelfDamageModule) -> OffensiveAnimationData:

	var Callables : Array[Callable]
	Callables.append(DamageShip.bind(Performer, Mod.GetFinalDamage(Action.Tier)))
	
	var AnimData = OffensiveAnimationData.new()
	AnimData.Mod = Mod
	
	var Data : Dictionary
	Data["Def"] = null
	Data["Viz"] = Performer.ShipViz
	var DefList : Dictionary[BattleShipStats, Dictionary]
	DefList[Performer] = Data
	AnimData.DeffenceList = DefList
	
	AnimData.Callables = Callables
	
	return AnimData


func HandleRecoil(Performer : BattleShipStats, _Action : CardStats, DamageAmm : float, Mod : RecoilDamageModule) -> OffensiveAnimationData:
	var Callables : Array[Callable]
	var Recoil = Mod.GetRecoilAmmount(DamageAmm)
	Callables.append(DamageShip.bind(Performer, Recoil))
	
	var AnimData = OffensiveAnimationData.new()
	AnimData.Mod = Mod
	
	var Data : Dictionary
	Data["Def"] = null
	Data["Viz"] = Performer.ShipViz
	var DefList : Dictionary[BattleShipStats, Dictionary]
	DefList[Performer] = Data
	AnimData.DeffenceList = DefList
	AnimData.Callables = Callables
	
	return AnimData


func HandleShield(Performer : BattleShipStats, Action : CardStats, Mod : ShieldCardModule, TargetOverride : Array[BattleShipStats] = []) -> DeffensiveAnimationData:
	#var viz = GetShipViz(Performer)
	var Targets : Array[BattleShipStats]
	if (TargetOverride.size() > 0):
		Targets = TargetOverride
	else:
		var Ts = await HandleTargets(Mod, Performer)
		for g in Ts:
			Targets.append(g)

	var TargetViz : Array[Control]
	
	var Callables : Array[Callable]
	
	for g in Targets:
		if (g == null):
			continue
		TargetViz.append(g.ShipViz)
		Callables.append(ShieldShip.bind(g, Mod.GetShieldAmm(Action.Tier)))
	
	var Data = DeffensiveAnimationData.new()
	Data.Mod = Mod
	Data.Targets = TargetViz
	Data.Callables = Callables
	return Data

func HandleMaxShield(Performer : BattleShipStats, Action : CardStats, Mod : MaxShieldCardModule, TargetOverride : Array[BattleShipStats] = []) -> DeffensiveAnimationData:
	var ShieldAmm = Performer.Energy * Mod.GetShieldPerEnergy(Action.Tier)
	
	var Targets : Array[BattleShipStats]
	if (TargetOverride.size() > 0):
		Targets = TargetOverride
	else:
		var Ts = await HandleTargets(Mod, Performer)
		for g in Ts:
			Targets.append(g)

	var TargetViz : Array[Control]
	
	var Callables : Array[Callable]
	
	for g in Targets:
		if (g == null):
			continue
		TargetViz.append(g.ShipViz)
		Callables.append(ShieldShip.bind(g, ShieldAmm))
	
	var Friendly = IsShipFriendly(Performer)
	
	UpdateEnergy(Performer, 0, Friendly)
	
	var Data = DeffensiveAnimationData.new()
	Data.Mod = Mod
	Data.Targets = TargetViz
	Data.Callables = Callables
	return Data

func HandleCauseFire(Performer : BattleShipStats, _Action : CardStats, Mod : CauseFireModule, TargetOverride : Array[BattleShipStats] = []) -> DeffensiveAnimationData:
	#var viz = GetShipViz(Performer)
	var Targets : Array[BattleShipStats]
	if (TargetOverride.size() > 0):
		Targets = TargetOverride
	else:
		var Ts = await HandleTargets(Mod, Performer)
		for g in Ts:
			Targets.append(g)
	var TargetViz : Array[Control]
	
	var Callables : Array[Callable]
	
	for g in Targets:
		if (g == null):
			continue
		TargetViz.append(g.ShipViz)
		Callables.append(CauseFire.bind(g))
		
	var Data = DeffensiveAnimationData.new()
	Data.Mod = Mod
	Data.Targets = TargetViz
	Data.Callables = Callables
	return Data


func HandleDamageStack(_Performer : BattleShipStats, Action : CardStats, Mod : StackDamageCardModule) -> DeffensiveAnimationData:
	var OffensiveModule = Action.OnPerformModule.duplicate() as OffensiveCardModule
	var NewAction = Action.duplicate()
	NewAction.OnPerformModule = OffensiveModule
	Action = NewAction
	OffensiveModule.Damage += OffensiveModule.Damage * Mod.GetStackDamage(Action.Tier)
	var Targets : Array[Control]
	var Data = DeffensiveAnimationData.new()
	Data.Mod = Mod
	Data.Targets = Targets
	return Data

func HandleBuffStrip(Performer : BattleShipStats, Mod : LoseBuffSelfModule) -> DeffensiveAnimationData:
	var Targets : Array[BattleShipStats]

	var Ts = await HandleTargets(Mod, Performer)
	for g in Ts:
		Targets.append(g)
	var TargetViz : Array[Control]
	
	var Callables : Array[Callable]

	for g in Targets:
		if (g == null):
			continue
		TargetViz.append(g.ShipViz)
		Callables.append(StripBuffFromShip.bind(g, Mod.StatToStrip))

		
	var Data = DeffensiveAnimationData.new()
	Data.Mod = Mod
	Data.Targets = TargetViz
	Data.Callables = Callables
	return Data

func HandleBuff(Performer : BattleShipStats, Action : CardStats, Mod : BuffModule, TargetOverride : Array[BattleShipStats] = []) -> DeffensiveAnimationData:
	var Targets : Array[BattleShipStats]
	if (TargetOverride.size() > 0):
		Targets = TargetOverride
	else:
		var Ts = await HandleTargets(Mod, Performer)
		for g in Ts:
			Targets.append(g)
	var TargetViz : Array[Control]
	
	var Callables : Array[Callable]
	
	var DebuffAmmount = Mod.GetBuffAmmount(Action.Tier)
	var DebuffDurration = Mod.GetBuffDuration(Action.Tier)
	
	for g in Targets:
		if (g == null):
			continue
		TargetViz.append(g.ShipViz)
		
		if (Mod.StatToBuff == CardModule.Stat.FIREPOWER):
			Callables.append(BuffShip.bind(g, DebuffAmmount, DebuffDurration))
		else : if (Mod.StatToBuff == CardModule.Stat.SPEED):
			Callables.append(BuffShipSpeed.bind(g, DebuffAmmount, DebuffDurration))
		else : if (Mod.StatToBuff == CardModule.Stat.DEFENCE):
			Callables.append(BuffShipDefence.bind(g, DebuffAmmount, DebuffDurration))
		
	var Data = DeffensiveAnimationData.new()
	Data.Mod = Mod
	Data.Targets = TargetViz
	Data.Callables = Callables
	return Data

func HandleDebuffCleanse(Performer : BattleShipStats, Mod : CleanseDebuffModule, TargetOverride : Array[BattleShipStats] = []) -> DeffensiveAnimationData:
	var Targets : Array[BattleShipStats]
	if (TargetOverride.size() > 0):
		Targets = TargetOverride
	else:
		var Ts = await HandleTargets(Mod, Performer)
		for g in Ts:
			Targets.append(g)
		
	var TargetViz : Array[Control]
	
	var Callables : Array[Callable]
	
	for g in Targets:
		if (g == null):
			continue
		TargetViz.append(g.ShipViz)

		Callables.append(CleanseShipDebuffs.bind(g))
	
	var Data = DeffensiveAnimationData.new()
	Data.Mod = Mod
	Data.Targets = TargetViz
	Data.Callables = Callables
	return Data

func HandleDeBuff(Performer : BattleShipStats, Action : CardStats, Mod : CardModule, TargetOverride : Array[BattleShipStats] = []) -> DeffensiveAnimationData:
	var Targets : Array[BattleShipStats]
	if (TargetOverride.size() > 0):
		Targets = TargetOverride
	else:
		var Ts = await HandleTargets(Mod, Performer)
		for g in Ts:
			Targets.append(g)
		
	var TargetViz : Array[Control]
	
	var Callables : Array[Callable]
	
	var DebuffAmmount = Mod.GetDebuffAmmount(Action.Tier)
	var DebuffDurration = Mod.GetDebuffDuration(Action.Tier)
	
	for g in Targets:
		if (g == null):
			continue
		TargetViz.append(g.ShipViz)

		if (Mod.StatToDeBuff == CardModule.Stat.FIREPOWER):
			Callables.append(DeBuffShipSpeed.bind(g, DebuffAmmount, DebuffDurration))
		else : if (Mod.StatToDeBuff == CardModule.Stat.SPEED):
			Callables.append(DeBuffShipSpeed.bind(g, DebuffAmmount, DebuffDurration))
		else : if (Mod.StatToDeBuff == CardModule.Stat.DEFENCE):
			Callables.append(DeBuffShipDefence.bind(g, DebuffAmmount, DebuffDurration))
			
	var Data = DeffensiveAnimationData.new()
	Data.Mod = Mod
	Data.Targets = TargetViz
	Data.Callables = Callables
	return Data


func HandleTargets(Mod : CardModule, User : BattleShipStats) -> Array[BattleShipStats]:
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.CARD_FIGHT_TARGET_PICKING)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.CARD_FIGHT_TARGET_PICKING)
		ActionTracker.GetInstance().ShowTutorial("Target Picking", "Some cards require you to pick a target, weather that is a friendly or enemy depends on the card.\nOther cards can be multi target, meaning they instantly target the whole team, or self use meaning they are used by the performer. Those cards will be used instantly without asking for a target.", [], true)
	
	var Friendly = IsShipFriendly(User)
	
	var Targets : Array[BattleShipStats]
	# we handle deffensive target picking a bit differently
	if (Mod is DeffenceCardModule):
		var Team = GetShipsTeam(User)
		if (!Mod.SelfUse):
			Team.erase(User)
		#If aoe pick all team either if enemy of player
		if (Mod.AOE):
			for g in Team:
				Targets.append(g)
		else: if Team.size() == 1:
			Targets.append(Team[0])
		#If can be used on others prompt player to choose, or if enemy pick randomly
		else: if Mod.CanBeUsedOnOther:
			if (Friendly):
				TargetSelect.SetEnemies(Team)
				SelectingTarget = true
				var Target = await TargetSelect.EnemySelected
				if (Target != null):
					Targets.append(Target)
				SelectingTarget = false
			else:
				if (Mod is BuffModule):
					Targets.append(GetTargetWithBiggestStat(Team, Mod.StatToBuff))
				else:
					Targets.append(Team.pick_random())
		#if nothing of the above counts pick the user as the target
		else:
			Targets = [User]
	else:
		var EnemyTeam = GetShipEnemyTeam(User)
		#If aoe pick all enemy team either if enemy of player
		if (Mod.AOE):
			for g in EnemyTeam:
				Targets.append(g)
		#If there is only 1 
		else: if EnemyTeam.size() == 1:
			Targets.append(EnemyTeam[0])
		else:
			if (Friendly):
				TargetSelect.SetEnemies(EnemyTeam)
				SelectingTarget = true
				var Target = await TargetSelect.EnemySelected
				if (Target != null):
					Targets.append(Target)
				SelectingTarget = false
			else:
				Targets.append(GetBestTargetForAtack(EnemyTeam))
	
	return Targets

#func GetBestTargetForAtack(Candidates : Array[BattleShipStats]) -> BattleShipStats:
	#var CurrentBiggestPoints : float = 999999999999
	#var CurrentTarget : BattleShipStats
	#
	#for g in Candidates:
		#var Points = g.CurrentHull + (g.DefDebuff * 1000) + (g.GetFirePower() * 500)
		#if (CurrentBiggestPoints > Points):
			#CurrentTarget = g
			#CurrentBiggestPoints = Points
	#
	#return CurrentTarget

func GetBestTargetForAtack(Candidates : Array) -> BattleShipStats:
	var points_list = []
	for g in Candidates:
		var points = (g.DefDebuff * 1000) + (g.GetFirePower() * 500) - g.CurrentHull
		points_list.append(points)
	
	var total_points = 0.0
	for p in points_list:
		total_points += max(0, p) # avoid negatives
	
	# Pick based on weighted chance
	var rand = randf() * total_points
	var cumulative = 0.0
	for i in range(Candidates.size()):
		cumulative += max(0, points_list[i])
		if rand <= cumulative:
			return Candidates[i]

	# As fallback (should not happen), return a random one
	return Candidates[randi() % Candidates.size()]

func GetTargetWithBiggestStat(Candidates : Array[BattleShipStats], St : CardModule.Stat) -> BattleShipStats:
	var CurrentBiggestStat: float = 0
	var CurrentTarget : BattleShipStats
	
	for g in Candidates:
		var Stat : float
		if (St== CardModule.Stat.FIREPOWER):
			Stat = g.GetFirePower()
		else : if (St == CardModule.Stat.SPEED):
			Stat = g.GetSpeed()
		else : if (St == CardModule.Stat.DEFENCE):
			Stat = g.GetDef()

		if (CurrentBiggestStat < Stat):
			CurrentTarget = g
			CurrentBiggestStat = Stat
	
	return CurrentTarget

func HandleDrawCard(Performer : BattleShipStats, ConsumeEnergy : bool = false) -> bool:
	if (Shuffling):
		PopUpManager.GetInstance().DoFadeNotif("Shuffling in progress")
		return false
	
	var D = GetShipDeck(Performer)
	
	if (D.DeckPile.size() <= 0):
		await HandleShuffleDiscardedIntoDeck(D)
	
	if (D.DeckPile.size() == 0):
		return false
		
	if (ConsumeEnergy):
		UpdateEnergy(Performer, Performer.Energy - 1, true)
	
	
	var C = D.DeckPile.pop_front()
	
	var c = CardScene.instantiate() as Card
	c.SetCardBattleStats(Performer, C)
	#c.connect("OnCardPressed", OnCardSelected)
	
	ExternalUI.DeckUI.OnCardDrawn()
	
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
	
	if (D.DeckPile.size() > 0):
		var C = D.DeckPile.pop_front()
		
		PlaceCardInEnemyHand(Performer, C)
	
	await DoCardDrawAnimation(Performer.ShipViz)


func HandleDrawSpecificCard(Performer : BattleShipStats, Spawn : CardStats) -> void:
	
	var D = GetShipDeck(Performer)
	
	if (D.DeckPile.size() <= 0):
		await HandleShuffleDiscardedIntoDeck(D)
			
	var HasCardInDeck : bool = false
	
	for g : CardStats in D.DeckPile:
		if (Spawn.IsSame(g)):
			HasCardInDeck = true
			break
	
	if (!HasCardInDeck):
		await HandleShuffleDiscardedIntoDeck(D)
	
	var c = CardScene.instantiate() as Card
	c.SetCardBattleStats(Performer, Spawn)
	#c.connect("OnCardPressed", OnCardSelected)
	
	ExternalUI.DeckUI.OnCardDrawn()
	
	D.DeckPile.erase(Spawn)
	
	var Placed = await PlaceCardInPlayerHand(Performer, c)
	
	if (Placed):
		pass
		#call_deferred("DoCardPlecementAnimation", c, ExternalUI.GetDeckkPile().global_position)
	else:
		c.queue_free()

func HandleMultiDrawSpecific(Performer : BattleShipStats, Mod : MultiCardSpawnModule) -> void:
	
	var D = GetShipDeck(Performer)
	
	if (D.DeckPile.size() <= 0):
			await HandleShuffleDiscardedIntoDeck(D)
			
	var PossibleCards : Array[CardStats]
	
	for g : CardStats in D.DeckPile:
		var Exists : bool = false
		for C in PossibleCards:
			if (C.IsSame(g)):
				Exists = true
				break
		if (Exists):
			continue
		if (Mod.TestCard(g.OnPerformModule)):
			PossibleCards.append(g)
			continue
		for m in g.OnUseModules:
			if (Mod.TestCard(m)):
				PossibleCards.append(g)
				break
	
	CardSelect.SetCardsPick(Performer, PossibleCards)
	
	SelectingTarget = true
	var Picked = await CardSelect.CardSelected
	SelectingTarget = false
	
	var c = CardScene.instantiate() as Card
	c.SetCardBattleStats(Performer, PossibleCards[Picked])

	ExternalUI.DeckUI.OnCardDrawn()
	
	D.DeckPile.erase(PossibleCards[Picked])
	
	var Placed = await PlaceCardInPlayerHand(Performer, c)
	
	if (Placed):
		pass
		#call_deferred("DoCardPlecementAnimation", c, ExternalUI.GetDeckkPile().global_position)
	else:
		c.queue_free()

func HandleMultiDrawSpecificEnemy(Performer : BattleShipStats, Mod : MultiCardSpawnModule) -> void:
	
	var D = GetShipDeck(Performer)
	
	if (D.DeckPile.size() <= 0):
			await HandleShuffleDiscardedIntoDeck(D)
	
	var PossibleCards : Array[CardStats]
	
	for g : CardStats in D.DeckPile:
		var Exists : bool = false
		for C in PossibleCards:
			if (C.IsSame(g)):
				Exists = true
				break
		if (Exists):
			continue
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
	var D = GetShipDeck(Performer)
	
	if (D.DeckPile.size() <= 0):
		await HandleShuffleDiscardedIntoDeck(D)
	
	var HasCardInDeck : bool = false

	for g : CardStats in D.DeckPile:
		if (Spawn.IsSame(g)):
			HasCardInDeck = true
			break
	
	if (!HasCardInDeck):
		HandleShuffleDiscardedIntoDeck(D, false)
	
	D.DeckPile.erase(Spawn)
	
	PlaceCardInEnemyHand(Performer ,Spawn)

var Shuffling : bool = false

func HandleShuffleDiscardedIntoDeck(D : Deck, DoAnim : bool = true) -> void:
	Shuffling = true
	PopUpManager.GetInstance().DoFadeNotif("Shuffling Deck")
	if (DoAnim):
		for g in D.DiscardPile.size():
			await Helper.GetInstance().wait(0.05)
			ExternalUI.DiscardPile.OnCardRemoved()
			ExternalUI.DeckUI.OnCardAdded(ExternalUI.DiscardPile.global_position)
				
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

func DoCardAnim(Action : CardStats, Data : Array[AnimationData], Performer : BattleShipStats, _FriendShip : bool) -> void:
	#print("Starting Def Anim")
	var ActionAnim : PackedScene = ResourceLoader.load(ActionAnimFile)
	var anim = ActionAnim.instantiate() as CardOffensiveAnimation
	AnimationPlecement.add_child(anim)
	AnimationPlecement.move_child(anim, 1)
	anim.DoAnimation(Action, Data, Performer, _FriendShip)
	
	for g in Data:
		if (g is OffensiveAnimationData):
			for C in g.Callables:
				await anim.AtackConnected
				C.call()
		else : if (g is DeffensiveAnimationData):
			for C in g.Callables:
				await anim.DeffenceConnected
				C.call()
	
	await(anim.AnimationFinished)
	anim.visible = false
	anim.queue_free()

func DoCardSelectAnimation(Action : CardStats, Performer : BattleShipStats, User : Control) -> void:
	var ActionAnim : PackedScene = ResourceLoader.load(ActionAnimFile)
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

func DoCardDrawAnimation(User : Control) -> void:
	var ActionAnim : PackedScene = ResourceLoader.load(ActionAnimFile)
	var anim = ActionAnim.instantiate() as CardOffensiveAnimation
	AnimationPlecement.add_child(anim)
	AnimationPlecement.move_child(anim, 1)
	anim.DoDraw(User)
	
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

#////////////////////////////////////////////////////////////////////////////
 #██████  ███████ ████████ ████████ ███████ ██████  ███████ 
#██       ██         ██       ██    ██      ██   ██ ██      
#██   ███ █████      ██       ██    █████   ██████  ███████ 
#██    ██ ██         ██       ██    ██      ██   ██      ██ 
 #██████  ███████    ██       ██    ███████ ██   ██ ███████ 
#////////////////////////////////////////////////////////////////////////////
#Usefull getters

func GetCurrentShip() -> BattleShipStats:
	if (ShipTurns.size() - 1 < CurrentTurn):
		return null
	return ShipTurns[CurrentTurn]

func GetShipsTeam(Ship : BattleShipStats) -> Array[BattleShipStats]:
	var Team : Array[BattleShipStats]
	if (IsShipFriendly(Ship)):
		for g in PlayerCombatants:
			Team.append(g)
	else:
		for g in EnemyCombatants:
			Team.append(g)
	return Team


func GetShipEnemyTeam(Ship : BattleShipStats) -> Array[BattleShipStats]:
	var Team : Array[BattleShipStats]
	if (IsShipFriendly(Ship)):
		for g in EnemyCombatants:
			Team.append(g)
	else:
		for g in PlayerCombatants:
			Team.append(g)
	return Team


func GetShipDeck(Ship : BattleShipStats) -> Deck:
	if (IsShipFriendly(Ship)):
		return PlayerDecks[Ship]
	return EnemyDecks[Ship]


func GetFightingUnitAmmount(Ships : Array[BattleShipStats]) -> int:
	var CombatantAmmount = 0
	for g in Ships:
		if (g == null):
			continue
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
func DamageShip(Ship : BattleShipStats, Amm : float, ShouldCauseFire : bool = false, SkipShield : bool = false) -> bool:
	var Dmg = Amm - min(1, (Amm * Ship.GetDef()))
	if (!SkipShield):
		if Ship.Shield > 0:
			var origshield = Ship.Shield
			Ship.Shield = max(0,origshield - Amm)
			Dmg -= origshield - Ship.Shield
	
	#only do fire roll when shield didt absorb all the damage
	if (Dmg > 0 and TrySetFire()):
		CauseFire(Ship)
	
	Ship.CurrentHull -= Dmg
	
	if (ShouldCauseFire):
		CauseFire(Ship)
	
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
		if (await ShipDestroyed(Ship)):
			return true
		#else:
			#CheckForReserves()
	else:
		UpdateShipStats(Ship)
	return false


func ShieldShip(Ship : BattleShipStats, Amm : float) -> void:
	Ship.Shield = min(Ship.Shield + Amm, Ship.MaxShield)
	UpdateShipStats(Ship)

func StripBuffFromShip(Ship : BattleShipStats, Stat : CardModule.Stat) -> void:
	if (Stat == CardModule.Stat.FIREPOWER):
		Ship.FirePowerBuff = 1
		Ship.FirePowerBuffTime = 0
	if (Stat == CardModule.Stat.SPEED):
		Ship.SpeedBuff = 1
		Ship.SpeedBuffTime = 0
	if (Stat == CardModule.Stat.DEFENCE):
		Ship.DefBuff = 0
		Ship.DefBuffTime = 0
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

func CleanseShipDebuffs(Ship : BattleShipStats) -> void:
	Ship.FirePowerDeBuff = 0
	Ship.SpeedDeBuff = 0
	Ship.DefDebuff = 0
	UpdateShipStats(Ship)

func DeBuffShipSpeed(Ship : BattleShipStats, Amm : float, Turns : int = 2) -> void:
	#buffs are usually 1.2 or 1.3 so we keep the 0.2 and add it
	Ship.SpeedDeBuff += Amm
	Ship.SpeedDeBuffTime = Turns
	
	UpdateShipStats(Ship)

func BuffShipDefence(Ship : BattleShipStats, Amm : float, Turns : int = 2) -> void:
	#buffs are usually 1.2 or 1.3 so we keep the 0.2 and add it
	Ship.DefBuff += Amm
	Ship.DefBuffTime = Turns
	
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
	
	await ReplaceShip(Ship)
	#RemoveShip(Ship)
	
	var EnemiesDead = GetFightingUnitAmmount(EnemyCombatants) == 0 and GetFightingUnitAmmount(EnemyReserves) == 0
	var PlayerDead = GetFightingUnitAmmount(PlayerCombatants) == 0 and GetFightingUnitAmmount(PlayerReserves) == 0
	
	if (EnemiesDead or PlayerDead):
		
		GameOver = true
		await Helper.GetInstance().wait(3)
		call_deferred("OnFightEnded", EnemiesDead)
		return true
		
	return false


func TrySetFire() -> bool:
	randomize()
	var random_value = randf()
	return random_value < 0.2


func CauseFire(BattleS : BattleShipStats) -> void:
	if (BattleS.IsOnFire):
		BattleS.TurnsOnFire += 1
	else:
		BattleS.IsOnFire = true
		BattleS.TurnsOnFire = 0
	UpdateShipStats(BattleS)

func CombustFire(BattleS : BattleShipStats) -> void:
	BattleS.IsOnFire = false
	BattleS.TurnsOnFire = 0
	UpdateShipStats(BattleS)

func RemoveShip(Ship : BattleShipStats) -> void:
	var ShipViz = Ship.ShipViz
	ShipViz.ShipDestroyed()
	
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

func CreateShipVisuals(BattleS : BattleShipStats, Friendly : bool) -> CardFightShipViz2:
	var VizScene : PackedScene = ResourceLoader.load(ShipVizScene)
	var ShipVisuals = VizScene.instantiate() as CardFightShipViz2

	ShipVisuals.SetStats(BattleS, Friendly)
	
	if (Friendly):
		PlayerShipVisualPlecement.add_child(ShipVisuals)
	else :
		EnemyShipVisualPlecement.add_child(ShipVisuals)
	
	BattleS.ShipViz = ShipVisuals

	NewTurnStarted.connect(ShipVisuals.OnNewTurnStarted)
	
	return ShipVisuals
	
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
	
	ExternalUI.UpdateCardsInHandAmm(CharDeck.Hand.size(), MaxCardsInHand)


func UpdateCardDescriptions(User : BattleShipStats):
	var Cards = get_tree().get_nodes_in_group("Card")
	for g : Card in Cards:
		g.UpdateBattleStats(User)
		


func UpdateShipStats(BattleS : BattleShipStats) -> void:
	#var Friendly = IsShipFriendly(BattleS)
	var viz = BattleS.ShipViz
	viz.UpdateStats(BattleS)
	viz.ToggleDmgBuff(BattleS.FirePowerBuff > 1, BattleS.FirePowerBuff)
	viz.ToggleSpeedBuff(BattleS.SpeedBuff > 1, BattleS.SpeedBuff)
	viz.ToggleDefBuff(BattleS.DefBuff > 0, BattleS.DefBuff)
	
	viz.ToggleDmgDebuff(BattleS.FirePowerDeBuff > 0)
	viz.ToggleSpeedDebuff(BattleS.SpeedDeBuff > 0)
	viz.ToggleDefDeBuff(BattleS.DefDebuff > 0)
	if (ShipTurns.find(BattleS) == CurrentTurn):
		UpdateCardDescriptions(BattleS)
	viz.ToggleFire(BattleS.IsOnFire)


func UpdateEnergy(Ship : BattleShipStats, NewEnergy : float, UpdateUI : bool) -> void:
	var OldEnergy = Ship.Energy
	var RoundedEnergy = roundi(NewEnergy)
	Ship.Energy = RoundedEnergy
	if (UpdateUI):
		ExternalUI.GetEnergyBar().UpdateAmmount(OldEnergy, RoundedEnergy)
		if (NewEnergy > ExternalUI.GetEnergyBar().GetSegmentAmm()):
			ExternalUI.GetEnergyBar().ChangeSegmentAmm(Ship.Energy)
	
		UpdateCardDescriptions(Ship)

func UpdateReserves(Ship : BattleShipStats, NewEnergy : float, UpdateUI : bool) -> void:
	var OldEnergy = Ship.EnergyReserves
	var RoundedEnergy = roundi(NewEnergy)
	Ship.EnergyReserves = RoundedEnergy
	if (UpdateUI):
		ExternalUI.GetReserveBar().UpdateAmmount(OldEnergy, RoundedEnergy)
		if (NewEnergy > ExternalUI.GetReserveBar().GetSegmentAmm()):
			ExternalUI.GetReserveBar().ChangeSegmentAmm(Ship.EnergyReserves)
	
		UpdateCardDescriptions(Ship)

func UpdateFleetSizeAmmount() -> void:
	PlayerFleetSizeLabel.text = "Fleet Size\n{0}".format([PlayerReserves.size() + PlayerCombatants.size()])
	EnemyFleetSizeLabel.text = "Fleet Size\n{0}".format([EnemyReserves.size() + EnemyCombatants.size()])
	

func ClearCards() -> void:
	ExternalUI.ClearHand()
	for g in SelectedCardPlecement.get_children():
		g.free()

var HandCountTween : Tween

func NotifyFullHand() -> void:
	PopUpManager.GetInstance().DoFadeNotif("Hand is full")
	if (HandCountTween and HandCountTween.is_running()):
		HandCountTween.kill()
	
	HandCountTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).set_parallel(true)
	#HandCountTween.tween_property(HandAmmountLabel,"scale", Vector2(1.2, 1.2), 0.55)
	
	HandCountTween.finished.connect(NotifyFullHandStage2)
	
func NotifyFullHandStage2() -> void:
	HandCountTween.kill()
	
	HandCountTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel(true)
	#HandCountTween.tween_property(HandAmmountLabel,"scale", Vector2.ONE, 0.55)


func _on_deck_button_pressed() -> void:
	if (SelectingTarget):
		PopUpManager.GetInstance().DoFadeNotif("Finish selecting target")
		ExternalUI.CardDrawFail()
		return
	if (EnemyPickingMove):
		PopUpManager.GetInstance().DoFadeNotif("Enemy is selecting their moves")
		ExternalUI.CardDrawFail()
		return
	if (CurrentPhase != CardFightPhase.ACTION_PICK):
		PopUpManager.GetInstance().DoFadeNotif("Can't perform outside of Action Pick phase")
		ExternalUI.CardDrawFail()
		return
	if (!PickingMoves):
		ExternalUI.CardDrawFail()
		return
	
	var Ship = GetCurrentShip()

	var Energy = Ship.Energy
	
	if (Energy < 1):
		ExternalUI.GetEnergyBar().NotifyNotEnough()
		ExternalUI.CardDrawFail()
		PopUpManager.GetInstance().DoFadeNotif("Not enough energy")
		return
	
	
	await HandleDrawCard(Ship, true)


func _on_pull_reserves_pressed() -> void:
	if (SelectingTarget):
		PopUpManager.GetInstance().DoFadeNotif("Finish selecting target")
		return
	if (EnemyPickingMove):
		PopUpManager.GetInstance().DoFadeNotif("Enemy is selecting their moves")
		return
	if (CurrentPhase != CardFightPhase.ACTION_PICK):
		PopUpManager.GetInstance().DoFadeNotif("Can't perform outside of Action Pick phase")
		return
	if (!PickingMoves):
		return
		
	var currentship = GetCurrentShip()
	var Reserv = currentship.EnergyReserves
	currentship.EnergyReserves = 0
	UpdateEnergy(currentship, currentship.Energy + Reserv, true)
	UpdateReserves(currentship, 0, true)
	

func _on_switch_ship_pressed() -> void:
	if (SelectingTarget):
		PopUpManager.GetInstance().DoFadeNotif("Finish selecting target")
		return
	if (EnemyPickingMove):
		PopUpManager.GetInstance().DoFadeNotif("Enemy is selecting their moves")
		return
	if (CurrentPhase != CardFightPhase.ACTION_PICK):
		PopUpManager.GetInstance().DoFadeNotif("Can't perform outside of Action Pick phase")
		return
	if (!PickingMoves):
		return
	if (PlayerReserves.size() == 0):
		PopUpManager.GetInstance().DoFadeNotif("No available ships to switch too")
		return
	var CurrentShip = GetCurrentShip()

	TargetSelect.SetEnemies(PlayerReserves, true)
	SelectingTarget = true
	var NewCombatant = await TargetSelect.EnemySelected
	SelectingTarget = false
	
	if (NewCombatant == null):
		return
	
	var ShipViz = CurrentShip.ShipViz
	await ShipViz.ShipDestroyed()
	
	ShipViz.get_parent().remove_child(ShipViz)
	add_child(ShipViz)
	
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
		print("{0} added to {1}'s hand".format([C.CStats.GetCardName(), Performer.Name]))
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
			print("{0} has been added to {1}'s discard pile.".format([C.CStats.GetCardName(), Performer.Name]))
			PlDeck.DiscardPile.append(C.CStats)
			ExternalUI.DiscardPile.OnCardDiscarded(ExternalUI.DeckUI.global_position)
			ExternalUI.ToggleHandInput(true)
			return false
		
		PlDeck.Hand.append(C.CStats)
		
		#var Plecement = PlayerCardPlecement.get_child(ToDiscard)
		var Discarded : Card = ExternalUI.GetPlayerCardPlecement().get_child(ToDiscard)
		await ExternalUI.InsertCardToDiscard(Discarded)
		print("{0} has been added to {1}'s discard pile.".format([Discarded.CStats.GetCardName(), Performer.Name]))
		PlDeck.DiscardPile.append(Discarded.CStats)
		ExternalUI.DiscardPile.OnCardDiscarded(Discarded.global_position + (Discarded.size / 2))
		Discarded.get_parent().queue_free()
		ExternalUI.OnCardDrawn(C)
		PlDeck.Hand.erase(Discarded.CStats)
		
		ExternalUI.ToggleHandInput(true)
	
	C.call_deferred("UpdateBattleStats", Performer)
	ExternalUI.UpdateCardsInHandAmm(PlDeck.Hand.size(), MaxCardsInHand)
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
		print("{0} has been added to {1}'s hand pile.".format([C.GetCardName(), Performer.Name]))
	else:
		EnemyDeck.Hand.append(C)
		var ToDiscard = EnemyDeck.Hand.pick_random()
		EnemyDeck.Hand.erase(ToDiscard)
		print("{0} has been added to {1}'s discard pile.".format([ToDiscard.GetCardName(), Performer.Name]))
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
	if (EnemyReserves.size() == 0):
		for g in ShipAmm:
			EnemyReserves.append(load(GetRandomCaptain(true)).GetBattleStats())
	if (PlayerReserves.size() == 0):
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

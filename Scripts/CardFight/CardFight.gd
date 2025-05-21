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
@export var UIInSound : AudioStream
@export var UIOutSound : AudioStream
@export var RemoveCardSound : AudioStream
@export_group("Plecement Referances")
#Plecement for any atack cards player can play
#@export var PlayerCardPlecement : Control
#Plecement for any cards player selects to play
@export var SelectedCardPlecement : Control
@export var AnimationPlecement : Control
#@export var EnergyBarParent : Control
#@export var EnergyBar : SegmentedBar
#@export var ReservesBar : SegmentedBar
@export var EnemyShipVisualPlecement : Control
@export var PlayerShipVisualPlecement : Control
@export var TargetSelect : CardFightTargetSelection
@export var CardSelect : CardFightDiscardSelection
@export var CardSelectContainer : Control
@export var ActionDeclaration : Control
@export var ShipSpacer : Control
@export var HandAmmountLabel : Label
@export var Cloud : ColorRect
@export var DiscardP : DiscardPileUI
@export var DeckP : DeckPileUI
@export var PlayerFleetSizeLabel : Label
@export var EnemyFleetSizeLabel : Label
#@export var ShipFallBackButton : Button
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

#Stored stats for each ship in battle. Once ship is killed in battle this stat is deleted
#Once fight is done this stats are retrieved. If a ship's stats is missing that means it got killed in battle so we kill it in overworld to
#var PlayerShips : Array[BattleShipStats]
var PlayerReserves : Array[BattleShipStats]
var PlayerCombatants : Array[BattleShipStats]
var PlayerDecks : Dictionary[BattleShipStats, Deck]
#var EnemyShips : Array[BattleShipStats]
var EnemyReserves : Array[BattleShipStats]
var EnemyCombatants : Array[BattleShipStats]
var EnemyDecks : Dictionary[BattleShipStats, Deck]
#Stored UI visualisation for ships
var ShipsViz : Dictionary[BattleShipStats, CardFightShipViz2]



var ActionList = CardFightActionList.new()

var SelectingTarget : bool = false
var EnemyPickingMove : bool = false
var PlayerPerformingMove : bool = false

signal CardFightEnded(Survivors : Array[BattleShipStats])

#TODO
#ACTION WRAPPER
#WRAPPER THAT HOLDS IN ALL DATA FOR AN ACTION DONE

#TODO
#Find way to expand system to work with inventory items. DONE
#need to make sure that any armaments brought into the fight exist inside inventory. DONE
#armaments that can be used in map will be different to those used in card fight DONE
#Card fight armaments will also be resupplied in same way in towns. DONE
#enemies need to have inventory of armaments to see what they can do in fight SEMI-DONE

var CardSelectSize : float

func _ready() -> void:
	ExternalUI = ExternalCardFightUI.GetInstacne()
	ExternalUI.RegisterFight(self)
	ExternalUI.OnDeckPressed.connect(_on_deck_button_pressed)
	ExternalUI.OnEndTurnPressed.connect(PlayerActionSelectionEnded)
	ExternalUI.OnShipFallbackPressed.connect(_on_switch_ship_pressed)
	#ExternalUI.CardPlayed.connect(OnCardSelected)
	ExternalUI.OnPullReserves.connect(_on_pull_reserves_pressed)
	MusicManager.GetInstance().SwitchMusic(true)
	ExternalUI.GetEnergyBar().Init(TurnEnergy)
	ExternalUI.GetReserveBar().Init(0)

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
	
	CreateDecks()

	DeckP.visible = false
	DiscardP.visible = false
	ExternalUI.ToggleEnergyVisibility(false)
	#ShipFallBackButton.visible = false
	HandAmmountLabel.visible = false
	call_deferred("StoreContainerSize")
	
	Helper.GetInstance().CallLater(RunTurn, 2)
	
func InitRandomFight(ShipAmm : int) -> void:
	#for g in ShipAmm:
		#EnemyReserves.append(GenerateRandomisedShip("en{0}".format([g]), true))
#
	#for g in ShipAmm:
		#PlayerReserves.append(GenerateRandomisedShip("pl{0}".format([g]), false))
	for g in ShipAmm:
		EnemyReserves.append(load(GetRandomCaptain(true)).GetBattleStats())

	for g in ShipAmm:
		PlayerReserves.append(load(GetRandomCaptain(false)).GetBattleStats())


func CheckForReserves() -> void:
	if (PlayerCombatants.size() < MaxCombatants and PlayerReserves.size() > 0):
		var NewCombatant = PlayerReserves.pick_random()
		PlayerCombatants.append(NewCombatant)
		PlayerReserves.erase(NewCombatant)
		
		ShipTurns.append(NewCombatant)
		ShipTurns.sort_custom(speed_comparator)
		CreateShipVisuals(NewCombatant, true)
		CreateDecks()
	if (EnemyCombatants.size() < MaxCombatants and EnemyReserves.size() > 0):
		var NewCombatant = EnemyReserves.pick_random()
		EnemyCombatants.append(NewCombatant)
		EnemyReserves.erase(NewCombatant)
		
		ShipTurns.append(NewCombatant)
		ShipTurns.sort_custom(speed_comparator)
		CreateShipVisuals(NewCombatant, false)
		CreateDecks()
	
	UpdateFleetSizeAmmount()
		
func CreateDecks() -> void:
	#Create the deck
	for g in ShipTurns:
		if PlayerDecks.keys().has(g) or EnemyDecks.keys().has(g):
			continue
		var D = Deck.new()
		
		var ShipCards = g.Cards.keys()
		#var ShipAmmo = g.Ammo.keys()
		
		for Crd : CardStats in ShipCards:
			#var WType = Crd.WeapT
			var Amm = 0
			#if (Crd.Consume):
			Amm = g.Cards[Crd]
				
			for Dup in Amm:
				D.DeckPile.append(Crd)
			
			#for Ammo in ShipAmmo:
				#var am = Ammo as CardOption
				#if (am.ComatibleWeapon == WType):
					##var c2 = CardScene.instantiate() as Card
					#var Cstats2 = Crd.duplicate()
					#Cstats2.SelectedOption = am
					#var Amm2 = 0
					#if (am.CauseConsumption):
						#Amm2 = g.Ammo[Ammo]
					#
					#for Dup in Amm2:
						#D.DeckPile.append(Cstats2)
		#Create Hand
		D.DeckPile.shuffle()
		for Hand in StartingCardAmm:
			var C = D.DeckPile.pop_front()
			D.Hand.append(C)
			#D.DeckPile.erase(C)
			
		if (IsShipFriendly(g)):
			PlayerDecks[g] = D
		else:
			EnemyDecks[g] = D

func DoCardAnim(OriginalPos : Vector2, Target : Control) -> void:
	var c = CardThing.instantiate() as CardViz
	c.Target = Target
	AnimationPlecement.add_child(c)
	c.global_position = OriginalPos

func StoreContainerSize() -> void:
	CardSelectSize = CardSelectContainer.get_parent().size.y
	CardSelectContainer.get_parent().size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	#CardSelectContainer.custom_minimum_size.y = CardSelectSize
	CardSelectContainer.get_parent().visible = false
	
	ActionDeclaration.get_child(0).visible = false
	ActionDeclaration.get_child(0).modulate = Color(1,1,1,0)
	ActionDeclaration.visible = false

func DoActionDeclaration(ActionName : String, CustomTime : float = 3) -> void:
	
	
	ActionDeclaration.visible = true
	ActionDeclaration.get_child(0).text = ActionName
	var Tw = create_tween()
	Tw.set_ease(Tween.EASE_OUT)
	Tw.set_trans(Tween.TRANS_QUAD)
	Tw.tween_property(ActionDeclaration, "custom_minimum_size", Vector2(650, 80), CustomTime/6)
	
	var InSound = DeletableSoundGlobal.new()
	InSound.stream = UIInSound
	InSound.autoplay = true
	InSound.bus = "MapSounds"
	InSound.pitch_scale = randf_range(0.9, 1.1)
	add_child(InSound)
	
	await Tw.finished
	
	ActionDeclaration.get_child(0).visible = true
	
	var Tw2 = create_tween()
	Tw2.set_ease(Tween.EASE_OUT)
	Tw2.set_trans(Tween.TRANS_QUAD)
	Tw2.tween_property(ActionDeclaration.get_child(0), "modulate", Color(1,1,1,1), CustomTime/6)
	await Tw2.finished
	
	await wait((CustomTime/6) *2)
	
	var Tw3 = create_tween()
	Tw3.set_ease(Tween.EASE_OUT)
	Tw3.set_trans(Tween.TRANS_QUAD)
	Tw3.tween_property(ActionDeclaration.get_child(0), "modulate", Color(1,1,1,0), CustomTime/6)
	await Tw3.finished
	
	ActionDeclaration.get_child(0).visible = false
	
	var Tw4 = create_tween()
	Tw4.set_ease(Tween.EASE_OUT)
	Tw4.set_trans(Tween.TRANS_QUAD)
	Tw4.tween_property(ActionDeclaration, "custom_minimum_size", Vector2(0, 80), CustomTime/6)
	
	var OutSound = DeletableSoundGlobal.new()
	OutSound.stream = UIOutSound
	OutSound.autoplay = true
	OutSound.bus = "MapSounds"
	OutSound.pitch_scale = randf_range(0.9, 1.1)
	add_child(OutSound)
	
	await Tw4.finished
	#ShipSpacer.visible = false
	ActionDeclaration.visible = false

func wait(secs : float) -> Signal:
	return get_tree().create_timer(secs).timeout

#function to sort battle ships based on their speed
static func speed_comparator(a, b):
	if a.GetSpeed() > b.GetSpeed():
		return true  # -1 means 'a' should appear before 'b'
	elif a.GetSpeed()< b.GetSpeed():
		return false  # 1 means 'b' should appear before 'a'
	return true
	
func CreateShipVisuals(BattleS : BattleShipStats, Friendly : bool) -> void:
	var t = ShipVizScene2.instantiate() as CardFightShipViz2
	#t.disabled = true
	#t.connect("pressed", ShipVizPressed.bind(BattleS))
	var Hbox = HBoxContainer.new()
	var C = Control.new()

	t.SetStats(BattleS, Friendly)
	
	if (Friendly):
		PlayerShipVisualPlecement.add_child(Hbox)
		Hbox.add_child(C)
		Hbox.add_child(t)
	else :
		Hbox.alignment = BoxContainer.ALIGNMENT_END
		EnemyShipVisualPlecement.add_child(Hbox)
		Hbox.add_child(t)
		Hbox.add_child(C)
	
	#C.custom_minimum_size.x = 180
	#C.visible = false
	
	ShipsViz[BattleS] = t

func ShipVizPressed(Ship : BattleShipStats) -> void:
	var Scene = CardFightShipInfoScene.instantiate() as CardFightShipInfo
	Scene.SetUpShip(Ship)
	add_child(Scene)

func GetShipDeck(Ship : BattleShipStats) -> Deck:
	if (IsShipFriendly(Ship)):
		return PlayerDecks[Ship]
	return EnemyDecks[Ship]

func GetShipViz(BattleS : BattleShipStats) -> CardFightShipViz2:
	return ShipsViz[BattleS]
	
func UpdateShipStats(BattleS : BattleShipStats) -> void:
	var Friendly = IsShipFriendly(BattleS)
	var viz = GetShipViz(BattleS)
	viz.UpdateStats(BattleS)
	viz.ToggleDmgBuff(BattleS.FirePowerBuff > 1, BattleS.FirePowerBuff)
	viz.ToggleSpeedBuff(BattleS.SpeedBuff > 1, BattleS.SpeedBuff)
	viz.ToggleDmgDebuff(BattleS.FirePowerDeBuff > 0)
	viz.ToggleSpeedDebuff(BattleS.SpeedDeBuff > 0)

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

signal PlayerActionPickingEnded

func RunTurn() -> void:
	ShipSpacer.visible = true
	await DoActionDeclaration("Action Pick Phase", 2)
	ShipSpacer.visible = false
	
	for Ship in ShipTurns:
		var viz = GetShipViz(Ship)

		var ExpiredBuffs = Ship.UpdateBuffs()
		for g in ExpiredBuffs:
			var d = DamageFloater.instantiate() as Floater
			d.modulate = Color(1,0,0,1)
			d.text = g + " +\nExpired"
			add_child(d)
			d.global_position = (viz.global_position + (viz.size / 2)) - d.size / 2
			await d.Ended
			
		UpdateShipStats(Ship)
	
	ShipTurns.sort_custom(speed_comparator)
	
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.CARD_FIGHT_ACTION_PICK)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.CARD_FIGHT_ACTION_PICK)
		ActionTracker.GetInstance().ShowTutorial("Action Picking Phase", "In the Action Picking Phase each ship picks their moves for the upcomming Action Performing Phase, the ships with the bigger speed get to pick and perform their moves first. Limited time is given for each ship to pick their moves. All offensive actions have a possible deffence, make sure you keep your ship's protected while maintaining a steady offensive.", [], true)
	
	CardSelectContainer.get_parent().visible = true
	CardSelectContainer.get_child(0).visible = false
	var Tw2 = create_tween()
	Tw2.set_ease(Tween.EASE_OUT)
	Tw2.set_trans(Tween.TRANS_QUAD)
	Tw2.tween_property(CardSelectContainer.get_parent(), "custom_minimum_size", Vector2(0,CardSelectSize), 0.5)
	await Tw2.finished
	
	CardSelectContainer.get_child(0).visible = true
	
	CurrentTurn = 0
	
	
	
	for Ship in ShipTurns:
		await DoActionDeclaration(Ship.Name + "'s turn", 1.5)
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
			#ShipFallBackButton.visible = true
			if (!ActionTracker.IsActionCompleted(ActionTracker.Action.CARD_FIGHT_RESERVES)):
				ActionTracker.OnActionCompleted(ActionTracker.Action.CARD_FIGHT_RESERVES)
				await ActionTracker.GetInstance().ShowTutorial("Energy Reserves", "Some cards can provide a ship with energy reserves. Energy reserves are kept until the player decides to use them and can be accumulated indefinetly. At any point the 'Pull Reserves' is pressed any amount of reserves kept on the ship will be lost and gained as energy to use on that turn.", [ExternalUI.GetReserveBar()], true)
			
			
			
			HandAmmountLabel.visible = true
			
			RestartCards()
			
			await PlayerActionPickingEnded
			ClearCards()
			
			DeckP.visible = false
			DiscardP.visible = false
			ExternalUI.ToggleEnergyVisibility(false)
			#ShipFallBackButton.visible = false
			HandAmmountLabel.visible = false
			#ATime.queue_free()
		else:
			EnemyPickingMove = true
			DrawCardEnemy(Ship)
			await EnemyActionSelection(Ship)
			EnemyPickingMove = false
		
		GetShipViz(ShipTurns[CurrentTurn]).Dissable()
		CurrentTurn += 1
	
		
	ClearCards()
	
	#Sort ships again to make sure speed buffs are taken into account
	ShipTurns.sort_custom(speed_comparator)
	#CardSelectContainer.custom_minimum_size.y = CardSelectSize
	
	CardSelectContainer.get_child(0).visible = false
	
	var Tw = create_tween()
	Tw.set_ease(Tween.EASE_OUT)
	Tw.set_trans(Tween.TRANS_QUAD)
	Tw.tween_property(CardSelectContainer.get_parent(), "custom_minimum_size", Vector2(0,0), 0.5)
	await Tw.finished
	CardSelectContainer.get_parent().visible = false
	DeckP.visible = false
	DiscardP.visible = false
	ExternalUI.ToggleEnergyVisibility(false)
	#DeckP.visible = false
	#DiscardP.visible = false
	#EnergyBarParent.visible = false
	#ShipFallBackButton.visible = false
	HandAmmountLabel.visible = false
	
	ShipSpacer.visible = true
	await DoActionDeclaration("Action Perform Phase", 2)
	ShipSpacer.visible = false
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.CARD_FIGHT_ACTION_PERFORM)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.CARD_FIGHT_ACTION_PERFORM)
		ActionTracker.GetInstance().ShowTutorial("Action Perform Phase", "In the Action Perform Phase each ship performs the moves they've picked in the Action Pick Phase.\nIn the end of the phase any unused card, like an extra deffensive card, will be returned to the discard pile.", [], true)
	
	#AnimationPlecement.visible = true
	CurrentTurn = 0
	for Ship in ShipTurns:
		var PerformedActions = await PerformActions(Ship)
		
		var D = GetShipDeck(Ship)
		
		for ToBurn in PerformedActions:
			ActionList.RemoveActionFromShip(Ship, ToBurn.Action)
			
			#Actions[Ship].erase(ToBurn)
			
		if (GameOver):
			return
		
		CurrentTurn += 1

	await DoFireDamage()
	
	#AnimationPlecement.visible = false
	
	if (GameOver):
		return
	
	RefundUnusedCards()
	ActionList.Clear()
	
	
	#Actions.clear()
	
	call_deferred("RunTurn")

func EnemyActionSelection(Ship : BattleShipStats) -> void:
	var EnemyEnergy = TurnEnergy + Ship.EnergyReserves
	Ship.EnergyReserves = 0
	
	var EnemyDeck = EnemyDecks[Ship]
	
	if (GetShipViz(Ship).IsOnFire()):
		var ExtinguishAction
		for g : CardStats in EnemyDeck.Hand:
			if (g.CardName == "Extinguish fires"):
				ExtinguishAction = g
				EnemyEnergy -= ExtinguishAction.Energy
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
		if (Actions.size() == 0 and EnemyEnergy > 1 and EnemyDeck.Hand.size() < MaxCardsInHand):
			print("{0} draws a card".format([Ship.Name]))
			DrawCardEnemy(Ship)
			Actions.clear()
			return EnemyDeck.Hand
		return Actions
		
	while (AvailableActions.size() > 0):
		var Action = (AvailableActions.pick_random() as CardStats)
		
		print("{0} tries to player card {1}".format([Ship.Name, Action.CardName]))
		
		if (!Action.AllowDuplicates and ActionList.ShipHasAction(Ship, Action)):
			AvailableActions.erase(Action)
			AvailableActions = t.call(AvailableActions)

		else: if (Action.CardName == "Extinguish fires" or Action.Energy > EnemyEnergy):
			print("{0} cant use {1}, not enough energy".format([Ship.Name, Action.CardName]))
			AvailableActions.erase(Action)
			AvailableActions = t.call(AvailableActions)

		else:
			print("{0} uses {1}".format([Ship.Name, Action.CardName]))
			var SelectedAction : CardStats = Action.duplicate()
			
			EnemyEnergy -= SelectedAction.Energy
			
			EnemyDeck.Hand.erase(Action)
			#EnemyDeck.DiscardPile.append(Action)
			AvailableActions.erase(Action)

			
			await HandleModulesEnemy(Ship, SelectedAction)
			
			if (SelectedAction.OnPerformModule == null):
				print("{0} has been added to {1}'s discard pile.".format([SelectedAction.CardName, Ship.Name]))
				EnemyDeck.DiscardPile.append(SelectedAction)
			else:
				await DoCardSelectAnimation(SelectedAction, GetShipViz(Ship))
				
				var ShipAction = CardFightAction.new()
				ShipAction.Action = SelectedAction

				ShipAction.Targets = await HandleTargets(Action.OnPerformModule, Ship)
				
				ActionList.AddAction(Ship, ShipAction)
				
			
			
			AvailableActions = t.call(AvailableActions)
			
		print("{0} ended their turn with {1} exess energy".format([Ship.Name, EnemyEnergy]))

func PerformActions(Ship : BattleShipStats) -> Array[CardFightAction]:

	var ActionsToBurn : Array[CardFightAction]
	var Friendly = IsShipFriendly(Ship)
	var viz = GetShipViz(Ship)
	var Dec = GetShipDeck(Ship)
	
	for g in viz.get_parent().get_children():
		if (g != viz):
			var tw = create_tween()
			tw.set_ease(Tween.EASE_OUT)
			tw.set_trans(Tween.TRANS_QUAD)
			tw.tween_property(g, "custom_minimum_size", Vector2(90, 0), 0.2)
			await tw.finished
			#g.visible = true
	for z in ActionList.GetShipsActions(Ship):
		var ShipAction = z as CardFightAction
		var Action = ShipAction.Action
		
		var Targets = ShipAction.Targets
			
		for g in Targets:
			if (!PlayerCombatants.has(g) and !EnemyCombatants.has(g)):
				Targets.erase(g)
		
		if (Targets.size() == 0):
			continue
		
		var Mod = Action.OnPerformModule
		
		if (Mod is OffensiveCardModule):

			ActionsToBurn.append(ShipAction)
			
			var Counter : CardStats
			var AtackType = Mod.AtackType
			#var HasDeff = false
			
			
			
			var anim = ActionAnim.instantiate() as CardOffensiveAnimation
			#anim.DrawnLine = true
			AnimationPlecement.add_child(anim)
			AnimationPlecement.move_child(anim, 1)

			#List containing targets and a bool saying if target has def
			var TargetList : Dictionary[BattleShipStats, Dictionary]
			
			for g in Targets:
				var HasDef : bool = false
				for Act : CardFightAction in ActionList.GetShipsActions(g):
					var mod = Act.Action.OnPerformModule
					if (mod is CounterCardModule):
						if (mod.CounterType == AtackType):
							HasDef = true
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
			
			anim.DoOffensive(Action, Mod, TargetList, Ship, Friendly)
			
			for g in TargetList:

				if (TargetList[g]["Def"] != null):
					continue
				else:
					for d in Mod.OnSuccesfullAtackModules:
						if (Friendly):
							HandleModule(Ship, Action, d)
						else:
							HandleModuleEnemy(Ship, Action, d)
					break

			for g in TargetList:
				#print("Atack Started")
				await anim.AtackConnected
				#print("Atack connected")
				if (TargetList[g]["Def"] != null):
					continue
				else:

					if (DamageShip(g, Mod.GetFinalDamage(Ship), Mod.CauseFile)):
						break

			if (!anim.Fin):
				#print("Animation Started")
				await anim.AnimationFinished
				#print("Animation Finished")
			
			DiscardP.visible = false
			
			anim.visible = false
			#print("Deleting animation")
			anim.queue_free()
			
			

	for g in viz.get_parent().get_children():
		if (g != viz):
			var tw = create_tween()
			tw.set_ease(Tween.EASE_OUT)
			tw.set_trans(Tween.TRANS_QUAD)
			tw.tween_property(g, "custom_minimum_size", Vector2(0, 0), 0.2)
			await tw.finished

	return ActionsToBurn

func HandleDrawDriscard(Performer : BattleShipStats, Mod : DrawCardModule) -> void:
	var D = GetShipDeck(Performer)
			
	var DrawAmmount = Mod.DrawAmmount
	var DiscardAmmount = Mod.DiscardAmmount
	
	var CardsToDraw : Array[Card] = []
	var CardsToDiscard : Array[Card] = []
	
	for g in DrawAmmount:
		if (D.DeckPile.size() == 0):
			await ShuffleDiscardedIntoDeck(D)
		
		var ToDraw = D.DeckPile.pop_front()
		var c = CardScene.instantiate() as Card
		c.SetCardStats(ToDraw)
		#c.connect("OnCardPressed", OnCardSelected)
		
		DeckP.OnCardDrawn()
		CardsToDraw.append(c)
	
	while CardsToDiscard.size() < DiscardAmmount:
		CardSelect.SetCards(CardsToDraw)
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
		await wait(0.2)
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
		if (D.DeckPile.size() == 0):
			await ShuffleDiscardedIntoDeck(D)
		
		var ToDraw = D.DeckPile.pop_front()
		CardsToDraw.append(ToDraw)
	
	while CardsToDiscard.size() < DiscardAmmount:
		var ToDiscard = CardsToDraw.pick_random()
		CardsToDraw.erase(ToDiscard)
		CardsToDiscard.append(ToDiscard)
		print("{0} has been added to {1}'s discard pile.".format([ToDiscard.CardName, Performer.Name]))
		D.DiscardPile.append(ToDiscard)
	
	for g in CardsToDraw:
		
		var Placed = PlaceCardInEnemyHand(Performer, g)

func HandleResupply(Performer : BattleShipStats, Action : CardStats, Mod : ResupplyModule) -> void:
	var resupplyamm = Mod.ResupplyAmmount

	var Targets = await HandleTargets(Mod, Performer)
	var TargetViz : Array[Control]
	
	for g in Targets:
		TargetViz.append(GetShipViz(g))

	for T in Targets:
		UpdateEnergy(T, T.Energy + resupplyamm, T == Performer)
			
	await DoDeffenceAnim(Action, Mod, TargetViz, IsShipFriendly(Performer), [])

func HandleReserveSupply(Performer : BattleShipStats, Action : CardStats, Mod : ReserveModule) -> void:
	var resupplyamm = Mod.ReserveAmmount

	var Targets = await HandleTargets(Mod, Performer)
	var TargetViz : Array[Control]
	
	for g in Targets:
		TargetViz.append(GetShipViz(g))

	for T in Targets:
		UpdateReserves(T, T.EnergyReserves + resupplyamm, T == Performer)
			
	await DoDeffenceAnim(Action, Mod, TargetViz, IsShipFriendly(Performer), [])

func HandleFireExtinguish(Performer : BattleShipStats, Action : CardStats, Mod : CardModule) -> void:
	var viz = GetShipViz(Performer)

	await DoDeffenceAnim(Action, Mod, [viz], IsShipFriendly(Performer), [viz.ToggleFire.bind(false)])
	
	
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
	var viz = GetShipViz(Performer)

	var Targets = await HandleTargets(Mod, Performer)
	var TargetViz : Array[Control]
	
	for g in Targets:
		TargetViz.append(GetShipViz(g))
	
	var Callables : Array[Callable]
	for T in Targets:
		Callables.append(ShieldShip.bind(T, Mod.ShieldAmm * Action.Tier))
	
	await DoDeffenceAnim(Action, Mod, TargetViz, EnemyCombatants.has(Performer), Callables)

func HandleCauseFire(Performer : BattleShipStats, Action : CardStats, Mod : CauseFireModule) -> void:
	var viz = GetShipViz(Performer)
	
	var Targets = await HandleTargets(Mod, Performer)
	var TargetViz : Array[Control]
	
	for g in Targets:
		TargetViz.append(GetShipViz(g))
	
	var Callables : Array[Callable]
	for T in Targets:
		Callables.append(ToggleFireToShip.bind(T, true))
		
	await DoDeffenceAnim(Action, Mod, TargetViz, EnemyCombatants.has(Performer), Callables)

func HandleBuff(Performer : BattleShipStats, Action : CardStats, Mod : BuffModule) -> void:
	var Targets = await HandleTargets(Mod, Performer)
	var TargetViz : Array[Control]
	
	for g in Targets:
		TargetViz.append(GetShipViz(g))
	
	var Callables : Array[Callable]
	for T in Targets:
		if (Mod.StatToBuff == CardModule.Stat.FIREPOWER):
			Callables.append(BuffShip.bind(T, Mod.BuffAmmount, Mod.BuffDuration))
		else : if (Mod.StatToBuff == CardModule.Stat.SPEED):
			Callables.append(BuffShipSpeed.bind(T, Mod.BuffAmmount, Mod.BuffDuration))
			
	await DoDeffenceAnim(Action, Mod, TargetViz, EnemyCombatants.has(Performer), Callables)

func HandleDeBuff(Performer : BattleShipStats, Action : CardStats, Mod : CardModule) -> void:
	var Targets = await HandleTargets(Mod, Performer)
	var TargetViz : Array[Control]
	
	for g in Targets:
		TargetViz.append(GetShipViz(g))
	
	var Callables : Array[Callable]
	for T in Targets:
		if (Mod.StatToDeBuff == CardModule.Stat.FIREPOWER):
			Callables.append(DeBuffShipSpeed.bind(T, Mod.DeBuffAmmount, Mod.DeBuffDuration))
		else : if (Mod.StatToDeBuff == CardModule.Stat.SPEED):
			Callables.append(DeBuffShipSpeed.bind(T, Mod.DeBuffAmmount, Mod.DeBuffDuration))
			
	await DoDeffenceAnim(Action, Mod, TargetViz, EnemyCombatants.has(Performer), Callables)

#Used to handle targeting both for player and enemies
func HandleTargets(Mod : CardModule, User : BattleShipStats) -> Array[BattleShipStats]:
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.CARD_FIGHT_TARGET_PICKING)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.CARD_FIGHT_TARGET_PICKING)
		ActionTracker.GetInstance().ShowTutorial("Target Picking", "Some cards require you to pick a target, weather that is a friendly or enemy depends on the card.\nOther cards can be multi target, meaning they instantly target the whole team, or self use meaning they are used by the performer. Those cards will be used instantly without asking for a target.", [], true)
	
	var Friendly = IsShipFriendly(User)
	
	var Targets : Array[BattleShipStats]
	# we handle deffensive target picking a bit differently
	if (Mod is DeffenceCardModule):
		#If aoe pick all team either if enemy of player
		if (Mod.AOE):
			Targets = GetShipsTeam(User)
			if (!Mod.SelfUse):
				Targets.erase(User)
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
					Targets.append(Target)
				SelectingTarget = false
			else:
				Targets.append(EnemyCombatants.pick_random())
		#if nothing of the above counts pick the user as the target
		else:
			Targets = [User]
	else:
		var EnemyTeam = GetShipEnemyTeam(User)
		#If aoe pick all enemy team either if enemy of player
		if (Mod.AOE):
			Targets = EnemyTeam

		#If there is only 1 
		else: if EnemyTeam.size() == 1:
			Targets.append(EnemyTeam[0])
		else:
			if (Friendly):
				TargetSelect.SetEnemies(EnemyCombatants)
				SelectingTarget = true
				var Target = await TargetSelect.EnemySelected
				if (Target != null):
					Targets.append(Target)
				SelectingTarget = false
			else:
				Targets.append(PlayerCombatants.pick_random())
	
	return Targets

func DoDeffenceAnim(Action : CardStats, Mod : CardModule, TargetViz : Array[Control], _FriendShip : bool, ToCallOnContact : Array[Callable]) -> void:
	#print("Starting Def Anim")
	var anim = ActionAnim.instantiate() as CardOffensiveAnimation
	AnimationPlecement.add_child(anim)
	AnimationPlecement.move_child(anim, 1)
	anim.DoDeffensive(Action, Mod, TargetViz, _FriendShip)
	
	
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
		
	anim.DoOffensive(Action, Mod, targs, ShipTurns[CurrentTurn], _FriendShip)
	
	
	for g in ToCallOnContact:
		await anim.AtackConnected
		g.call()
	
	await(anim.AnimationFinished)
	anim.visible = false
	anim.queue_free()

func DoCardSelectAnimation(Action : CardStats, User : Control) -> void:
	var anim = ActionAnim.instantiate() as CardOffensiveAnimation
	AnimationPlecement.add_child(anim)
	AnimationPlecement.move_child(anim, 1)
	anim.DoSelection(Action, User)
	
	var S = DeletableSoundGlobal.new()
	S.stream = CardPlecementSound
	S.autoplay = true
	S.pitch_scale = randf_range(0.8, 1.2)
	#S.bus = "MapSounds"
	add_child(S)
	S.volume_db = - 20
	
	await(anim.AnimationFinished)
	anim.visible = false
	anim.queue_free()

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

func DoFireDamage() -> void:
	for g in ShipTurns:
		var viz = GetShipViz(g)
		if (viz.IsOnFire()):
			
			var d = DamageFloater.instantiate() as Floater
			d.text = "Fire Damage"
			viz.add_child(d)
			d.global_position = (viz.global_position + (viz.size / 2)) - d.size / 2
			
			var GameEnded = DamageShip(g, 10)
			
			await d.Ended

			if (GameEnded):
				break
#////////////////////////////////////////////////////////////////////////////

# RETURN TRUE IF FIGHT IS OVER
func DamageShip(Ship : BattleShipStats, Amm : float, CauseFire : bool = false) -> bool:
	var Dmg = Amm
	if Ship.Shield > 0:
		var origshield = Ship.Shield
		Ship.Shield = max(0,origshield - Amm)
		Dmg -= origshield - Ship.Shield
	Ship.Hull -= Dmg

	if (CauseFire or TrySetFire()):
		ToggleFireToShip(Ship, true)
	
	if (IsShipFriendly(Ship)):
		
		if (Ship.Hull < 40 and !ActionTracker.IsActionCompleted(ActionTracker.Action.CARD_FIGHT_SHIPLOSS)):
			ActionTracker.OnActionCompleted(ActionTracker.Action.CARD_FIGHT_SHIPLOSS)
			ActionTracker.GetInstance().ShowTutorial("Lossing Ships", "When a ships hull reaches zero, they are threwn out of the fight and the capmaign. Make use of the 'Switch Ship' button to switch up ships in the fight. The ship that gets switched in loses one turn.", [], true)
	
		DamageGot += Dmg
		if (Dmg > 0):
			UIEventH.OnControlledShipDamaged(Dmg)
	else:
		DamageDone += Dmg
	
	if (Ship.Hull <= 0):
		if (ShipDestroyed(Ship)):
			return true
		else:
			CheckForReserves()
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

func IsShipFriendly(Ship : BattleShipStats) -> bool:
	return PlayerCombatants.has(Ship) or PlayerReserves.has(Ship)

func TrySetFire() -> bool:
	randomize()
	var random_value = randf()
	return random_value < 0.2

# RETURN TRUE IF FIGHT IS OVER
func ShipDestroyed(Ship : BattleShipStats) -> bool:
	
	
	if (EnemyCombatants.has(Ship)):
		FundsToWin += Ship.Funds
	
	RemoveShip(Ship)
	
	var EnemiesDead = GetFightingUnitAmmount(EnemyCombatants) == 0 and GetFightingUnitAmmount(EnemyReserves) == 0
	var PlayerDead = GetFightingUnitAmmount(PlayerCombatants) == 0 and GetFightingUnitAmmount(PlayerReserves) == 0
	
	if (EnemiesDead or PlayerDead):
		
		GameOver = true
		call_deferred("OnFightEnded", EnemiesDead)
		return true
		
	return false

func GetFightingUnitAmmount(Ships : Array[BattleShipStats]) -> int:
	var CombatantAmmount = 0
	for g in Ships:
		if (!g.Convoy):
			CombatantAmmount += 1
	return CombatantAmmount

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

#Refunds cards that consume inventory items if the card wasnt used in the end
func RefundUnusedCards() -> void:
	for Ship in PlayerCombatants:
		var Acts = ActionList.GetShipsActions(Ship)
		for z in Acts:
			var ShipAction = z as CardFightAction
			#if (!ShipAction.Action.ShouldConsume()):
				#continue
			RefundCardToShip(ShipAction.Action, Ship)
	for Ship in EnemyCombatants:
		var Acts = ActionList.GetShipsActions(Ship)
		for z in Acts:
			var ShipAction = z as CardFightAction
			#if (!ShipAction.Action.ShouldConsume()):
				#continue
			RefundCardToShip(ShipAction.Action, Ship)

func RefundCardToShip(C : CardStats, Ship : BattleShipStats):
	print("{0} got refunded a {1} card for not using it.".format([Ship.Name, C.CardName]))
	var deck = GetShipDeck(Ship)
	print("{0} has been added to {1}'s discard pile.".format([C.CardName, Ship.Name]))
	deck.DiscardPile.append(C)

func PlayerActionSelectionEnded() -> void:
	if (SelectingTarget or EnemyPickingMove or PlayerPerformingMove):
		return
	#GetShipViz(ShipTurns[CurrentTurn]).Dissable()
	PlayerActionPickingEnded.emit()

func RestartCards() -> void:
	ClearCards()
	
	var currentship = ShipTurns[CurrentTurn]

	ExternalUI.GetEnergyBar().ChangeSegmentAmm(TurnEnergy)
	ExternalUI.GetReserveBar().ChangeSegmentAmm(currentship.EnergyReserves)
	
	UpdateEnergy(currentship, TurnEnergy, true)
	UpdateReserves(currentship, currentship.EnergyReserves, true)
	UpdateHandCards()
	
	DiscardP.UpdateDiscardPileAmmount(PlayerDecks[ShipTurns[CurrentTurn]].DiscardPile.size())
	DeckP.UpdateDeckPileAmmount(PlayerDecks[ShipTurns[CurrentTurn]].DeckPile.size())
	#GetShipViz(ShipTurns[CurrentTurn]).Enable()
	
	CallLater(DrawCard.bind(currentship))
	
func CallLater(Call : Callable, t : float = 1) -> void:
	await get_tree().create_timer(t).timeout
	Call.call()

var Shuffling : bool = false

func DrawCardEnemy(Performer : BattleShipStats) -> void:
	var D = EnemyDecks[Performer]
	
	if (D.DeckPile.size() == 0):
		ShuffleDiscardedIntoDeck(D, false)
	
	var C = D.DeckPile.pop_front()
	
	PlaceCardInEnemyHand(Performer, C)

func ShuffleDiscardedIntoDeck(D : Deck, DoAnim : bool = true) -> void:
	Shuffling = true
	
	D.DeckPile.append_array(D.DiscardPile)
	D.DiscardPile.clear()
	
	D.DeckPile.shuffle()
	
	if (DoAnim):
		for g in D.DeckPile.size():
			await wait(0.05)
			DiscardP.OnCardRemoved()
			DeckP.OnCardAdded(DiscardP.global_position)
			if (g == D.DeckPile.size() - 1):
				await DeckP.CardAddFinished
	
	Shuffling = false


func DrawSpecificCardEnemy(Performer : BattleShipStats,Spawn : CardStats) -> void:
	var D = EnemyDecks[ShipTurns[CurrentTurn]]
	
	var HasCardInDeck : bool = false
	
	var C : CardStats
	
	for g : CardStats in D.DeckPile:
		if (g.CardName == Spawn.CardName):
			HasCardInDeck = true
			C = g
			break
	
	if (!HasCardInDeck):
		if (D.DeckPile.size() == 0):
			ShuffleDiscardedIntoDeck(D, false)
	
	PlaceCardInEnemyHand(Performer ,C)

func DrawCard(Performer : BattleShipStats) -> bool:
	if (Shuffling):
		return false
	
	var D = GetShipDeck(Performer)
	
	if (D.DeckPile.size() == 0):
		await ShuffleDiscardedIntoDeck(D)
	
	var C = D.DeckPile.pop_front()
	
	var c = CardScene.instantiate() as Card
	c.SetCardStats(C)
	#c.connect("OnCardPressed", OnCardSelected)
	
	DeckP.OnCardDrawn()
	
	var Placed = await PlaceCardInPlayerHand(Performer, c)
	
	if (Placed):
		pass
		#call_deferred("DoCardPlecementAnimation", c, ExternalUI.GetDeckkPile().global_position)
	else:
		c.queue_free()
		return true
	
	return true

func DrawSpecificCard(Performer : BattleShipStats, Spawn : CardStats) -> void:
	
	var D = GetShipDeck(Performer)
	
	var HasCardInDeck : bool = false
	
	for g : CardStats in D.DeckPile:
		if (g.CardName == Spawn.CardName):
			HasCardInDeck = true
			break
	
	if (!HasCardInDeck):
		if (D.DeckPile.size() == 0):
			await ShuffleDiscardedIntoDeck(D)
	
	var c = CardScene.instantiate() as Card
	c.SetCardStats(Spawn)
	#c.connect("OnCardPressed", OnCardSelected)
	
	DeckP.OnCardDrawn()
	
	D.DeckPile.erase(Spawn)
	
	var Placed = await PlaceCardInPlayerHand(Performer, c)
	
	if (Placed):
		pass
		#call_deferred("DoCardPlecementAnimation", c, ExternalUI.GetDeckkPile().global_position)
	else:
		c.queue_free()

func UpdateHandCards() -> void:
	
	ExternalUI.ClearHand()
	

	var CharDeck = GetShipDeck(ShipTurns[CurrentTurn])
	
	for ran in CharDeck.Hand:
		var c = CardScene.instantiate() as Card
		
		c.SetCardStats(ran)
		#c.connect("OnCardPressed", OnCardSelected)
		
		ExternalUI.AddCardToHand(c)

		
		#call_deferred("DoCardPlecementAnimation", c, ExternalUI.GetDeckkPile().global_position)
	
	UpdateHandAmount(CharDeck.Hand.size())

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
		var Hand : Array[Card]
		for g in ExternalUI.GetPlayerCardPlecement().get_children():
			Hand.append(g)
		#for g in SelectedCardPlecement.get_children():
			#if (g.get_child_count() > 0):
				#Hand.append(g.get_child(0))
				
		Hand.append(C)
		
		CardSelect.SetCards(Hand)
		SelectingTarget = true
		if (!ActionTracker.IsActionCompleted(ActionTracker.Action.CARD_FIGHT_HAND_LIMIT)):
			ActionTracker.OnActionCompleted(ActionTracker.Action.CARD_FIGHT_HAND_LIMIT)
			ActionTracker.GetInstance().ShowTutorial("Hand Limit", "At any time you can hold a max of {0} cards in your hand. If at any point an extra hand is about to be placed in your hand, you will be asked to choose one card to throw out. Picked card is placed on the discard pile.".format([MaxCardsInHand]), [], true)
		
		var ToDiscard : int = await CardSelect.CardSelected
		SelectingTarget = false

		if (ToDiscard == MaxCardsInHand):
			print("{0} has been added to {1}'s discard pile.".format([C.CStats.CardName, ShipTurns[CurrentTurn].Name]))
			PlDeck.DiscardPile.append(C.CStats)
			DiscardP.OnCardDiscarded(DeckP.global_position)
			return false
		
		
		
		PlDeck.Hand.append(C.CStats)
		
		#var Plecement = PlayerCardPlecement.get_child(ToDiscard)
		var Discarded : Card = ExternalUI.GetPlayerCardPlecement().get_child(ToDiscard)
		await ExternalUI.InsertCardToDiscard(Discarded)
		print("{0} has been added to {1}'s discard pile.".format([Discarded.CStats.CardName, ShipTurns[CurrentTurn].Name]))
		PlDeck.DiscardPile.append(Discarded.CStats)
		DiscardP.OnCardDiscarded(Discarded.global_position + (Discarded.size / 2))
		Discarded.get_parent().queue_free()
		ExternalUI.OnCardDrawn(C)
		PlDeck.Hand.erase(Discarded.CStats)
	
	UpdateHandAmount(PlDeck.Hand.size())
	return true

func PlaceCardInEnemyHand(Performer : BattleShipStats, C : CardStats) -> bool:
	var CanPlace : bool = false
	
	var EnemyDeck = EnemyDecks[Performer]
	
	var CardsInHand : int = EnemyDeck.Hand.size()

	if (CardsInHand < MaxCardsInHand):
		CanPlace = true

	EnemyDeck.DeckPile.erase(C)
	
	if (CanPlace):
		EnemyDeck.Hand.append(C)
	else:
		EnemyDeck.Hand.append(C)
		var ToDiscard = EnemyDeck.Hand.pick_random()
		EnemyDeck.Hand.erase(ToDiscard)
		print("{0} has been added to {1}'s discard pile.".format([ToDiscard.CardName, Performer.Name]))
		EnemyDeck.DiscardPile.append(ToDiscard)
	
	

	return true

func ClearCards() -> void:
	ExternalUI.ClearHand()

	for g in SelectedCardPlecement.get_children():
		g.free()

func DoCardPlecementAnimation(C : Card, OriginalPos : Vector2) -> void:
	var c = CardScene.instantiate() as Card
	
	c.SetCardStats(C.CStats)
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
	
#func MoveCard(Val : float, origpos : Vector2, C : Card, C2 : Card)  -> void:
	#C.global_position = lerp(origpos, C2.global_position, Val)

func OnCardSelected(C : Card) -> bool:
	
	if (SelectingTarget or EnemyPickingMove or Shuffling):
		return false
	
	var Ship = ShipTurns[CurrentTurn]
	
	if (Ship.Energy < C.GetCost()):
		ExternalUI.GetEnergyBar().NotifyNotEnough()
		PopUpManager.GetInstance().DoFadeNotif("Not enough energy")
		return false
	
	PlayerPerformingMove = true
	
	var deck = GetShipDeck(Ship)
	
	
	
	if (C.CStats.OnPerformModule != null):
		var Action : CardStats

		Action = C.CStats
		
		var c = CardScene.instantiate() as Card
		c.SetCardStats(Action)
		
		var ShipAction = CardFightAction.new()
		ShipAction.Action = Action
		
		var Mod = Action.OnPerformModule
		
		var CardPosition = C.global_position
		
		if (Mod is OffensiveCardModule):
			var targets = await HandleTargets(Mod, Ship)
			for g in targets:
				var TargetViz = GetShipViz(g)
				c.TargetLocs.append(TargetViz.global_position + TargetViz.size / 2)
			ShipAction.Targets.append_array(targets)
		
		var CurrentShip = ShipTurns[CurrentTurn]

		c.connect("OnCardPressed", RemoveCard)
		
		SelectedCardPlecement.add_child(c)

		ActionList.AddAction(CurrentShip, ShipAction)
		
		call_deferred("DoCardPlecementAnimation", c, CardPosition)
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
	
	UpdateEnergy(Ship, Ship.Energy - C.GetCost(), true)
	print("{0} has been removed from {1}'s hand.".format([C.CStats.CardName, Ship.Name]))
	deck.Hand.erase(C.CStats)
	
	if (C.CStats.Consume):
		var ShipCards = ShipTurns[CurrentTurn].Cards
		ShipCards[C.CStats] -= 1
		if (ShipCards[C.CStats] == 0):
			ShipCards.erase(C.CStats)
	
	#var Stats  = C.CStats
	await HandleModules(Ship, C.CStats)

	UpdateHandAmount(deck.Hand.size())
	PlayerPerformingMove = false

	return true

func HandleModules(Performer : BattleShipStats, C : CardStats) -> void:
	for Mod in C.OnUseModules.size():
		if (Mod == C.OnUseModules.size() - 1):
			await HandleModule(Performer, C ,C.OnUseModules[Mod])
		else:
			HandleModule(Performer, C ,C.OnUseModules[Mod])
			await wait(0.2)

func HandleModule(Performer : BattleShipStats, C : CardStats, Mod : CardModule) -> void:
	if (Mod is ResupplyModule):
		await HandleResupply(Performer, C, Mod)
	else :if (Mod is CauseFireModule):
		HandleCauseFire(Performer, C, Mod)
	else : if (Mod is ReserveModule):
		await HandleReserveSupply(Performer, C, Mod)
	else : if (Mod is DrawCardModule):
		HandleDrawDriscard(Performer, Mod)
	else : if (Mod is CardSpawnModule):
		var CardToSpawn = Mod.CardToSpawn
		DrawSpecificCard(Performer, CardToSpawn)
	else: if (Mod is FireExtinguishModule):
		await HandleFireExtinguish(Performer, C, Mod)
	else : if (Mod is BuffModule):
		await HandleBuff(Performer, C, Mod)
	else : if (Mod is DeBuffEnemyModule or Mod is DeBuffSelfModule):
		await HandleDeBuff(Performer, C, Mod)
	else : if (Mod is ShieldCardModule):
		await HandleShield(Performer, C, Mod)
	else : if (Mod is SelfDamageModule):
		await HandleSelfDamage(Performer, C, Mod)
	else : if (Mod is RecoilDamageModule):
		var AtackMod = C.OnPerformModule as OffensiveCardModule
		await HandleRecoil(Performer, C, AtackMod.GetFinalDamage(Performer), Mod)

func HandleModulesEnemy(Performer : BattleShipStats, C : CardStats) -> void:
	for Mod in C.OnUseModules.size():
		if (Mod == C.OnUseModules.size() - 1):
			await HandleModuleEnemy(Performer, C ,C.OnUseModules[Mod])
		else:
			HandleModuleEnemy(Performer, C ,C.OnUseModules[Mod])
			await wait(0.2)

func HandleModuleEnemy(Performer : BattleShipStats, C : CardStats,Mod : CardModule) -> void:
	if (Mod is ResupplyModule):
		await HandleResupply(Performer, C, Mod)
	else : if (Mod is ReserveModule):
		await HandleResupply(Performer, C, Mod)
	if (Mod is CauseFireModule):
		await HandleCauseFire(Performer, C, Mod)
	else : if (Mod is DrawCardModule):
		HandleDrawDiscardEnemy(Performer ,Mod)
	else : if (Mod is CardSpawnModule):
		var CardToSpawn = Mod.CardToSpawn
		DrawSpecificCardEnemy(Performer, CardToSpawn)
	else : if (Mod is FireExtinguishModule):
		await HandleFireExtinguish(Performer, C, Mod)
	else : if (Mod is BuffModule):
		await HandleBuff(Performer, C, Mod)
	else : if (Mod is DeBuffEnemyModule or Mod is DeBuffSelfModule):
		await HandleDeBuff(Performer, C, Mod)
	else : if (Mod is ShieldCardModule):
		await HandleShield(Performer, C, Mod)
	else : if (Mod is SelfDamageModule):
		await HandleSelfDamage(Performer, C, Mod)
	else : if (Mod is RecoilDamageModule):
		var AtackMod = C.OnPerformModule as OffensiveCardModule
		await HandleRecoil(Performer, C, AtackMod.GetFinalDamage(Performer), Mod)

func RemoveCard(C : Card) -> void:
	if (SelectingTarget or EnemyPickingMove):
		return
	
	var D = PlayerDecks[ShipTurns[CurrentTurn]]
	
	if (D.Hand.size() == MaxCardsInHand):
		NotifyFullHand()
		return
	
	if (C.CStats.OnUseModules.size() > 0):
		return
	
	C.disconnect("OnCardPressed", RemoveCard)
	
	#var S = DeletableSoundGlobal.new()
	#S.stream = RemoveCardSound
	#S.autoplay = true
	#add_child(S)
	#S.volume_db = -10

	if (C.CStats.Consume):
		var ShipCards = ShipTurns[CurrentTurn].Cards
		var HasCard = false
		for g in ShipCards.keys():
			#print("Comparing {0} with {1}".format([g.resource_path, C.CStats.resource_path]))
			if (g.CardName == C.CStats.CardName):
				HasCard = true
				ShipCards[g] += 1
				break
		if (!HasCard):
			ShipCards[C.CStats] = 1

	var CurrentShip = ShipTurns[CurrentTurn]
	
	ActionList.RemoveActionFromShip(CurrentShip, C.CStats)
	UpdateEnergy(CurrentShip, CurrentShip.Energy + C.GetCost(), true)
	

	D.Hand.append(C.CStats)
	UpdateHandAmount(D.Hand.size())
	
	#UpdateHandCards()
	var c = CardScene.instantiate() as Card
	c.SetCardStats(C.CStats)
	#c.connect("OnCardPressed", OnCardSelected)
	
	ExternalUI.OnCardDrawn(c)

	#call_deferred("DoCardPlecementAnimation", c, C.global_position)
	
	C.queue_free()

func UpdateEnergy(Ship : BattleShipStats, NewEnergy : float, UpdateUI : bool) -> void:
	var OldEnergy = Ship.Energy
	
	Ship.Energy = NewEnergy
	if (UpdateUI):
		ExternalUI.GetEnergyBar().UpdateAmmount(OldEnergy, NewEnergy)
		if (NewEnergy > max(OldEnergy, TurnEnergy)):
			ExternalUI.GetEnergyBar().ChangeSegmentAmm(Ship.Energy)

func UpdateReserves(Ship : BattleShipStats, NewEnergy : float, UpdateUI : bool) -> void:
	var OldEnergy = Ship.EnergyReserves
	
	Ship.EnergyReserves = NewEnergy
	if (UpdateUI):
		ExternalUI.GetReserveBar().UpdateAmmount(OldEnergy, NewEnergy)
		if (NewEnergy > OldEnergy):
			ExternalUI.GetReserveBar().ChangeSegmentAmm(Ship.EnergyReserves)

func UpdateFleetSizeAmmount() -> void:
	PlayerFleetSizeLabel.text = "Fleet Size\n{0}".format([PlayerReserves.size() + PlayerCombatants.size()])
	EnemyFleetSizeLabel.text = "Fleet Size\n{0}".format([EnemyReserves.size() + EnemyCombatants.size()])

var cloudtime : float = 0
func _physics_process(delta: float) -> void:
	cloudtime += delta * SimulationManager.SimSpeed()
	Cloud.material.set_shader_parameter("custom_time", cloudtime)

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

func _on_deck_button_pressed() -> void:
	var Ship = ShipTurns[CurrentTurn]

	var Energy = Ship.Energy
	
	if (SelectingTarget or Energy < 1 or EnemyPickingMove):
		ExternalUI.GetEnergyBar().NotifyNotEnough()
		return
	
	if (await DrawCard(Ship)):
		UpdateEnergy(Ship, Energy - 1, true)


func UpdateHandAmount(NewAmm : int) -> void:
	HandAmmountLabel.text = "In Hand {0}/{1}".format([NewAmm, MaxCardsInHand])

var HandCountTween : Tween

func NotifyFullHand() -> void:
	if (HandCountTween and HandCountTween.is_running()):
		HandCountTween.kill()
	
	HandCountTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).set_parallel(true)
	HandCountTween.tween_property(HandAmmountLabel,"scale", Vector2(1.2, 1.2), 0.55)

	await HandCountTween.finished
	HandCountTween.kill()
	
	HandCountTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel(true)
	HandCountTween.tween_property(HandAmmountLabel,"scale", Vector2.ONE, 0.55)


func _on_pull_reserves_pressed() -> void:
	var currentship = ShipTurns[CurrentTurn]
	var Reserv = currentship.EnergyReserves
	currentship.EnergyReserves = 0
	UpdateEnergy(currentship, currentship.Energy + Reserv, true)
	UpdateReserves(currentship, 0, true)
	

func _on_switch_ship_pressed() -> void:
	var CurrentShip = ShipTurns[CurrentTurn]

	TargetSelect.SetEnemies(PlayerReserves, true)
	SelectingTarget = true
	var NewCombatant = await TargetSelect.EnemySelected
	SelectingTarget = false
	
	if (NewCombatant == null):
		return
	
	var ShipViz = GetShipViz(CurrentShip)
	ShipViz.ShipDestroyed()
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
	CreateDecks()
	
	PlayerActionSelectionEnded()

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
@export var PlayerCardPlecement : Control
#Plecement for any cards player selects to play
@export var SelectedCardPlecement : Control
@export var AnimationPlecement : Control
@export var EnergyBarParent : Control
@export var EnergyBar : SegmentedBar
@export var ReservesBar : SegmentedBar
@export var EnemyShipVisualPlecement : Control
@export var PlayerShipVisualPlecement : Control
@export var TargetSelect : CardFightTargetSelection
@export var CardSelect : CardFightDiscardSelection
@export var CardSelectContainer : Control
@export var ActionDeclaration : Control
@export var ShipSpacer : Control
@export var HandAmmountLabel : Label
@export var Cloud : ColorRect
@export var DiscardP : DiscardPile
@export var DeckP : DeckPile
@export_group("FightSettings")
@export var StartingCardAmm : int = 5
@export var MaxCardsInHand : int = 10
@export var MaxCombatants : int = 5
@export var TurnEnergy : int = 10
#Stats kept to show at the end screen
var DamageDone : float = 0
var DamageGot : float = 0
var DamageNeg : float = 0
var FundsToWin : int = 0

var Energy : int = 10
var Reserv : int = 0

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
	EnergyBar.Init(TurnEnergy)
	ReservesBar.Init(0)
	if (OS.is_debug_build()):
		for g in 10:
			EnemyReserves.append(GenerateRandomisedShip("en{0}".format([g]), true))

		for g in 10:
			PlayerReserves.append(GenerateRandomisedShip("pl{0}".format([g]), false))
	
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

	#Create the visualisation for each ship, basicly their stat holder
	
	CreateDecks()

	DeckP.visible = false
	DiscardP.visible = false
	EnergyBarParent.visible = false
	HandAmmountLabel.visible = false
	call_deferred("StoreContainerSize")
	
	call_deferred("RunTurn")

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
		
func CreateDecks() -> void:
	#Create the deck
	for g in ShipTurns:
		if PlayerDecks.keys().has(g) or EnemyDecks.keys().has(g):
			continue
		var D = Deck.new()
		
		var ShipCards = g.Cards.keys()
		#var ShipAmmo = g.Ammo.keys()
		
		for Crd : CardStats in ShipCards:
			var WType = Crd.WeapT
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
			var C = D.DeckPile.pick_random()
			D.Hand.append(C)
			D.DeckPile.erase(C)
		
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
	viz.SetStats(BattleS, Friendly)
	viz.ToggleDmgBuff(BattleS.FirePowerBuff > 0)
	viz.ToggleSpeedBuff(BattleS.SpeedBuff > 0)

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
		
		ActionList.AddShip(Ship)
		if (IsShipFriendly(Ship)):
			DeckP.visible = true
			DiscardP.visible = true
			EnergyBarParent.visible = true
			HandAmmountLabel.visible = true
			
			RestartCards()
			#var ATime = AtackTime.instantiate() as AtackTimer
			#CardSelectContainer.get_parent().add_child(ATime)
			#ATime.connect("Finished", PlayerActionSelectionEnded)
			await PlayerActionPickingEnded
			ClearCards()
			
			DeckP.visible = false
			DiscardP.visible = false
			EnergyBarParent.visible = false
			HandAmmountLabel.visible = false
			#ATime.queue_free()
		else:
			EnemyPickingMove = true
			DrawCardEnemy()
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
	EnergyBarParent.visible = false
	HandAmmountLabel.visible = false
	
	ShipSpacer.visible = true
	await DoActionDeclaration("Action Perform Phase", 2)
	ShipSpacer.visible = false
	#AnimationPlecement.visible = true
	for Ship in ShipTurns:
		var PerformedActions = await PerformActions(Ship)
		
		var D = GetShipDeck(Ship)
		
		for ToBurn in PerformedActions:
			ActionList.RemoveActionFromShip(Ship, ToBurn.Action)
			
			#Actions[Ship].erase(ToBurn)
			
		if (GameOver):
			return

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
		for g in EnemyDeck.Hand:
			if (g.CardName == "Extinguish fires"):
				ExtinguishAction = g
				EnemyEnergy -= ExtinguishAction.Energy
				await HandleFireExtinguish(Ship, ExtinguishAction)
				EnemyDeck.Hand.erase(g)
				EnemyDeck.DiscardPile.append(g)
		#ActionList.AddAction(Ship, Action)
		#Actions[Ship].append(Action)
	
	var AvailableActions = EnemyDeck.Hand.duplicate()
	
	var t = func CheckIfToDraw() -> void:
		if (AvailableActions.size() == 0 and EnemyEnergy > 1 and EnemyDeck.Hand.size() < MaxCardsInHand):
			DrawCardEnemy()
			AvailableActions.clear()
			AvailableActions = EnemyDeck.Hand.duplicate()
	
	while (AvailableActions.size() > 0):
		var Action = (AvailableActions.pick_random() as CardStats)
		
		if (!Action.AllowDuplicates and ActionList.ShipHasAction(Ship, Action)):
			AvailableActions.erase(Action)
			t.call()
			continue
			
		if (Action.CardName == "Extinguish fires" or Action.Energy > EnemyEnergy):
			AvailableActions.erase(Action)
			t.call()
			continue
		
		var SelectedAction : CardStats = Action.duplicate()
		
		EnemyEnergy -= SelectedAction.Energy
		
		EnemyDeck.Hand.erase(Action)
		#EnemyDeck.DiscardPile.append(Action)
		AvailableActions.erase(Action)

		var ShipAction = CardFightAction.new()
		ShipAction.Action = SelectedAction

		ShipAction.Targets = await HandleTargets(Action, Ship)
		
		if (SelectedAction is Deffensive and SelectedAction.UseInstant):
			if (SelectedAction.Shield):
				await HandleShield(Ship, SelectedAction)
				EnemyDeck.DiscardPile.append(SelectedAction)
			
			if (SelectedAction is Buff):
				await HandleBuff(Ship, SelectedAction)
				EnemyDeck.DiscardPile.append(SelectedAction)
				
			if (SelectedAction.FireExt):
				await HandleFireExtinguish(Ship, SelectedAction)
				EnemyDeck.DiscardPile.append(SelectedAction)
				
		else: if (SelectedAction is ResupplyCardStats):
			var resupplyamm = SelectedAction.ResupplyAmmount
			EnemyEnergy += resupplyamm
			EnemyDeck.DiscardPile.append(SelectedAction)
			
		else: if (SelectedAction is CardSpawn):
			var CardToSpawn = SelectedAction.CardToSpawn
			EnemyDeck.DiscardPile.append(SelectedAction)
			DrawSpecificCardEnemy(CardToSpawn)
			AvailableActions.clear()
			AvailableActions = EnemyDeck.Hand.duplicate()
			
		else:
			await DoCardSelectAnimation(SelectedAction, GetShipViz(Ship))
			ActionList.AddAction(Ship, ShipAction)
		
		t.call()

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
			tw.tween_property(g, "custom_minimum_size", Vector2(180, 0), 0.2)
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
			
		if (Action is OffensiveCardStats):
				
			ActionsToBurn.append(ShipAction)
			
			var Counter = Action.GetCounter()
			#var HasDeff = false
			
			
			
			var anim = ActionAnim.instantiate() as CardOffensiveAnimation
			#anim.DrawnLine = true
			AnimationPlecement.add_child(anim)
			AnimationPlecement.move_child(anim, 1)

			#List containing targets and a bool saying if target has def
			var TargetList : Dictionary[BattleShipStats, Dictionary]
			
			for g in Targets:
				var HasDef : bool = false
				if (Counter != null):
					if (ActionList.ShipHasAction(g, Counter)):
						HasDef = true
				var Data : Dictionary
				Data["HasDef"] = HasDef
				Data["Viz"] = GetShipViz(g)
				TargetList[g] = Data
			
			
			anim.DoOffensive(Action, TargetList, Ship, Friendly)
			
			if (!Action.ShouldConsume()):
				Dec.DiscardPile.append(Action)
				if (Friendly):
					DiscardP.UpdateDiscardPileAmmount(Dec.DiscardPile.size())
					DiscardP.visible = true
					var pos = await anim.AtackCardDestroyed
					DiscardP.OnCardDiscarded(pos)
			
			for g in TargetList:
				var HadDef = TargetList[g]["HasDef"]
				if (HadDef):
					ActionList.RemoveActionFromShip(g, Counter)
					if (!Counter.ShouldConsume()):
						var TargetDeck = GetShipDeck(Targets[0])
						TargetDeck.DiscardPile.append(Counter)
						if (!Friendly):
							DiscardP.UpdateDiscardPileAmmount(TargetDeck.DiscardPile.size())
							DiscardP.visible = true
							var pos = await anim.DeffenceCardDestroyed
							DiscardP.OnCardDiscarded(pos)
					if (!Friendly):
						DamageNeg += Action.GetDamage() * Ship.GetFirePower()
			
			await anim.AnimationFinished
			
			DiscardP.visible = false
			
			anim.visible = false
			anim.queue_free()
			
			for g in TargetList:
				if (TargetList[g]["HasDef"]):
					continue
				else:
					if (DamageShip(g, Action.GetDamage() * Ship.GetFirePower(), Action.CauseFire())):
						break


	for g in viz.get_parent().get_children():
		if (g != viz):
			var tw = create_tween()
			tw.set_ease(Tween.EASE_OUT)
			tw.set_trans(Tween.TRANS_QUAD)
			tw.tween_property(g, "custom_minimum_size", Vector2(0, 0), 0.2)
			await tw.finished

	return ActionsToBurn

func HandleFireExtinguish(Performer : BattleShipStats, Action : CardStats) -> void:
	var viz = GetShipViz(Performer)
	
	viz.ToggleFire(false)
	#ActionsToBurn.append(ShipAction)
	if (Action.ShouldConsume()):
		var ShipCards = Performer.Cards
		ShipCards[Action] -= 1
		if (ShipCards[Action] == 0):
			ShipCards.erase(Action)
	
	
	await DoDeffenceAnim(Action, [viz], IsShipFriendly(Performer))
	
	
	

func HandleShield(Performer : BattleShipStats, Action : CardStats) -> void:
	var viz = GetShipViz(Performer)
	var ShieldAmm = 10

	var Targets = await HandleTargets(Action, Performer)
	var TargetViz : Array[Control]
	
	for g in Targets:
		TargetViz.append(GetShipViz(g))
		
	if (!Action.IsAOE()):
		ShieldAmm = 20
	
	for T in Targets:
		ShieldShip(T, ShieldAmm * Action.Tier)
	
	await DoDeffenceAnim(Action, TargetViz, EnemyCombatants.has(Performer))

func HandleBuff(Performer : BattleShipStats, Action : Buff) -> void:
	var Targets = await HandleTargets(Action, Performer)
	var TargetViz : Array[Control]
	
	for g in Targets:
		TargetViz.append(GetShipViz(g))
	
	for T in Targets:
		if (Action.StatToBuff == Buff.Stat.FIREPOWER):
			BuffShip(T, Action.BuffAmmount, Action.BuffDuration)
		else : if (Action.StatToBuff == Buff.Stat.SPEED):
			BuffShipSpeed(T, Action.BuffAmmount, Action.BuffDuration)
	
	await DoDeffenceAnim(Action, TargetViz, EnemyCombatants.has(Performer))
	

#Used to handle targeting both for player and enemies
func HandleTargets(Action : CardStats, User : BattleShipStats) -> Array[BattleShipStats]:
	var Friendly = IsShipFriendly(User)
	
	var Targets : Array[BattleShipStats]
	# we handle deffensive target picking a bit differently
	if (Action is Deffensive):
		#If aoe pick all team either if enemy of player
		if (Action.IsAOE()):
			Targets = GetShipsTeam(User)
		#If can be used on others prompt player to choose, or if enemy pick randomly
		else: if Action.CanBeUsedOnOther:
			if (Friendly):
				TargetSelect.SetEnemies(PlayerCombatants)
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
		if (Action.IsAOE()):
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

func DoDeffenceAnim(Action : CardStats, TargetViz : Array[Control], _FriendShip : bool) -> void:
	var anim = ActionAnim.instantiate() as CardOffensiveAnimation
	AnimationPlecement.add_child(anim)
	AnimationPlecement.move_child(anim, 1)
	anim.DoDeffensive(Action, TargetViz, _FriendShip)
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
			var anim = ActionAnim.instantiate() as CardOffensiveAnimation
			AnimationPlecement.add_child(anim)
			AnimationPlecement.move_child(anim, 1)
			anim.DoFire(g, IsShipFriendly(g))
			await(anim.AnimationFinished)
			anim.visible = false
			anim.queue_free()
			if (DamageShip(g, 10)):
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
		DamageGot += Dmg
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
	Ship.FirePowerBuff = Amm
	Ship.FirePowerBuffTime = Turns
	
	UpdateShipStats(Ship)

func BuffShipSpeed(Ship : BattleShipStats, Amm : float, Turns : int = 2) -> void:
	Ship.SpeedBuff = Amm
	Ship.SpeedBuffTime = Turns
	
	UpdateShipStats(Ship)

func IsShipFriendly(Ship : BattleShipStats) -> bool:
	return PlayerCombatants.has(Ship) or PlayerReserves.has(Ship)

func TrySetFire() -> bool:
	randomize()
	var random_value = randf()
	return random_value < 0.5

# RETURN TRUE IF FIGHT IS OVER
func ShipDestroyed(Ship : BattleShipStats) -> bool:
	if (EnemyCombatants.has(Ship)):
		FundsToWin += Ship.Funds
	
	RemoveShip(Ship)
	
	var EnemiesDead = GetFightingUnitAmmount(EnemyCombatants) == 0 and GetFightingUnitAmmount(EnemyReserves) == 0
	var PlayerDead = GetFightingUnitAmmount(PlayerCombatants) == 0 and GetFightingUnitAmmount(PlayerReserves) == 0
	
	if (EnemiesDead or PlayerDead):
		RefundUnusedCards()
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
	Survivors.append_array(PlayerCombatants)
	Survivors.append_array(PlayerReserves)
	Survivors.append_array(EnemyCombatants)
	Survivors.append_array(EnemyReserves)

	CardFightEnded.emit(Survivors)


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
	var HasCard = false
	for c in Ship.Cards.keys():
		if (c.CardName == C.CardName):
			Ship.Cards[c] += 1
			HasCard = true
			break
	if (!HasCard):
		Ship.Cards[C] = 1
		
	var deck = GetShipDeck(Ship)
	deck.DiscardPile.append(C)

func PlayerActionSelectionEnded() -> void:
	if (SelectingTarget or EnemyPickingMove):
		return
	#GetShipViz(ShipTurns[CurrentTurn]).Dissable()
	PlayerActionPickingEnded.emit()

func RestartCards() -> void:
	ClearCards()
	
	var currentship = ShipTurns[CurrentTurn]

	EnergyBar.ChangeSegmentAmm(TurnEnergy)
	ReservesBar.ChangeSegmentAmm(currentship.EnergyReserves)
	
	UpdateEnergy(0, TurnEnergy)
	UpdateReserves(0, currentship.EnergyReserves)
	UpdateHandCards()
	
	DiscardP.UpdateDiscardPileAmmount(PlayerDecks[ShipTurns[CurrentTurn]].DiscardPile.size())
	DeckP.UpdateDeckPileAmmount(PlayerDecks[ShipTurns[CurrentTurn]].DeckPile.size())
	#GetShipViz(ShipTurns[CurrentTurn]).Enable()
	
	CallLater(DrawCard)
	
func CallLater(Call : Callable, t : float = 1) -> void:
	await get_tree().create_timer(t).timeout
	Call.call()

var Shuffling : bool = false

func DrawCardEnemy() -> void:
	var D = EnemyDecks[ShipTurns[CurrentTurn]]
	
	if (D.DeckPile.size() == 0):
		ShuffleDiscardedIntoDeck(D, false)
	
	var C = D.DeckPile.pop_front()
	
	await PlaceCardInEnemyHand(C)

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


func DrawSpecificCardEnemy(Spawn : CardStats) -> void:
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
	
	await PlaceCardInEnemyHand(C)

func DrawCard() -> void:
	if (Shuffling):
		return
		
	var D = PlayerDecks[ShipTurns[CurrentTurn]]
	
	if (D.DeckPile.size() == 0):
		await ShuffleDiscardedIntoDeck(D)
	
	var C = D.DeckPile.pop_front()
	
	var c = CardScene.instantiate() as Card
	c.SetCardStats(C)
	c.connect("OnCardPressed", OnCardSelected)
	
	DeckP.OnCardDrawn()
	
	var Placed = await PlaceCardInPlayerHand(c)
	
	if (Placed):
		call_deferred("DoCardPlecementAnimation", c, DeckP.global_position)
	else:
		c.queue_free()

func DrawSpecificCard(Spawn : CardStats) -> void:
	if (Shuffling):
		return
	
	var D = PlayerDecks[ShipTurns[CurrentTurn]]
	
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
	c.connect("OnCardPressed", OnCardSelected)
	
	DeckP.OnCardDrawn()
	
	var Placed = await PlaceCardInPlayerHand(c)
	
	if (Placed):
		call_deferred("DoCardPlecementAnimation", c, DeckP.global_position)
	else:
		c.queue_free()

func UpdateHandCards() -> void:
	for g in PlayerCardPlecement.get_children():
		g.queue_free()
	

	var CharDeck = PlayerDecks[ShipTurns[CurrentTurn]]
	
	for ran in CharDeck.Hand:
		var c = CardScene.instantiate() as Card
		
		c.SetCardStats(ran)
		c.connect("OnCardPressed", OnCardSelected)
		
		PlayerCardPlecement.add_child(c)

		
		call_deferred("DoCardPlecementAnimation", c, DeckP.global_position)
	
	UpdateHandAmount(CharDeck.Hand.size())

func PlaceCardInPlayerHand(C : Card) -> bool:
	var CanPlace : bool = false
	
	var CardsInHand : int = PlayerCardPlecement.get_child_count()
	

	if (CardsInHand < MaxCardsInHand):
		CanPlace = true
			
	var PlDeck = PlayerDecks[ShipTurns[CurrentTurn]]
	PlDeck.DeckPile.erase(C.CStats)
	
	if (CanPlace):
		PlDeck.Hand.append(C.CStats)
		PlayerCardPlecement.add_child(C)

	else:
		var Hand : Array[Card]
		for g in PlayerCardPlecement.get_children():
			Hand.append(g)
		#for g in SelectedCardPlecement.get_children():
			#if (g.get_child_count() > 0):
				#Hand.append(g.get_child(0))
				
		Hand.append(C)
		
		CardSelect.SetCards(Hand)
		SelectingTarget = true
		var ToDiscard : int = await CardSelect.CardSelected
		SelectingTarget = false

		if (ToDiscard == MaxCardsInHand):
			PlDeck.DiscardPile.append(C.CStats)
			DiscardP.OnCardDiscarded(DeckP.global_position)
			return false

		PlDeck.Hand.append(C.CStats)
		
		#var Plecement = PlayerCardPlecement.get_child(ToDiscard)
		var Discarded : Card = PlayerCardPlecement.get_child(ToDiscard)
		PlDeck.DiscardPile.append(Discarded.CStats)
		DiscardP.OnCardDiscarded(Discarded.global_position + (Discarded.size / 2))
		Discarded.queue_free()
		PlayerCardPlecement.add_child(C)
		PlDeck.Hand.erase(Discarded.CStats)
	
	UpdateHandAmount(PlDeck.Hand.size())
	return true

func PlaceCardInEnemyHand(C : CardStats) -> bool:
	var CanPlace : bool = false
	
	var EnemyDeck = EnemyDecks[ShipTurns[CurrentTurn]]
	
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
		EnemyDeck.DiscardPile.append(ToDiscard)
	
	

	return true

func ClearCards() -> void:
	for g in PlayerCardPlecement.get_children():
		g.free()

	for g in SelectedCardPlecement.get_children():
		for z in g.get_children():
			z.free()

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
	PlecementTw.set_ease(Tween.EASE_OUT)
	PlecementTw.set_trans(Tween.TRANS_QUAD)
	var pos = C.global_position
	PlecementTw.tween_property(c, "global_position", C.global_position, 0.4)
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

func OnCardSelected(C : Card) -> void:
	#var Minigame = FightGame.instantiate() as FightMinigame
	#add_child(Minigame)
	#var Resault = await Minigame.Ended
	#Minigame.queue_free()

	if (SelectingTarget or EnemyPickingMove):
		return
	
	if (Energy < C.GetCost()):
		EnergyBar.NotifyNotEnough()
		return
	
	var deck = PlayerDecks[ShipTurns[CurrentTurn]]
	
	if (C.CStats is ResupplyCardStats):
		var resupplyamm = C.CStats.ResupplyAmmount
		#if (Energy + resupplyamm > 10):
			#return
		UpdateEnergy(Energy, Energy + resupplyamm)
		var pos = C.global_position
		C.get_parent().remove_child(C)
		add_child(C)
		C.global_position = pos
		C.KillCard(0.5, true)
		
		var S = DeletableSoundGlobal.new()
		S.stream = RemoveCardSound
		S.autoplay = true
		add_child(S)
		S.volume_db = -10
		
		
		deck.Hand.erase(C.CStats)
		deck.DiscardPile.append(C.CStats)
		DiscardP.OnCardDiscarded(C.global_position + (C.size / 2))
		return
	if (C.CStats is Reserve):
		var Reserveamm = C.CStats.ReserveAmmount
		#if (Energy + resupplyamm > 10):
			#return
		UpdateEnergy(Energy, Energy - C.GetCost())
		
		UpdateReserves(Reserv, Reserv + Reserveamm)
		var pos = C.global_position
		C.get_parent().remove_child(C)
		add_child(C)
		C.global_position = pos
		C.KillCard(0.5, true)
		
		var S = DeletableSoundGlobal.new()
		S.stream = RemoveCardSound
		S.autoplay = true
		add_child(S)
		S.volume_db = -10
		
		
		deck.Hand.erase(C.CStats)
		deck.DiscardPile.append(C.CStats)
		DiscardP.OnCardDiscarded(C.global_position + (C.size / 2))
		return
	if (C.CStats is DrawCard):
		UpdateEnergy(Energy, Energy - C.GetCost())
		#UpdateReserves(Reserv, Reserv + Reserveamm)
		var pos = C.global_position
		C.get_parent().remove_child(C)
		add_child(C)
		C.global_position = pos
		C.KillCard(0.5, true)
		
		var S = DeletableSoundGlobal.new()
		S.stream = RemoveCardSound
		S.autoplay = true
		add_child(S)
		S.volume_db = -10
		
		
		deck.Hand.erase(C.CStats)
		deck.DiscardPile.append(C.CStats)
		DiscardP.OnCardDiscarded(C.global_position + (C.size / 2))
		
		var D = PlayerDecks[ShipTurns[CurrentTurn]]
		
		var DrawAmmount = C.CStats.DrawAmmount
		var DiscardAmmount = C.CStats.DiscardAmmount
		
		var CardsToDraw : Array[Card] = []
		var CardsToDiscard : Array[Card] = []
		
		for g in DrawAmmount:
			if (D.DeckPile.size() == 0):
				await ShuffleDiscardedIntoDeck(D)
			
			var ToDraw = D.DeckPile.pop_front()
			var c = CardScene.instantiate() as Card
			c.SetCardStats(ToDraw)
			c.connect("OnCardPressed", OnCardSelected)
			
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
			D.DiscardPile.append(Ca.CStats)
			DeckP.OnCardDrawn()
			DiscardP.OnCardDiscarded(DeckP.global_position)
		
		for g in CardsToDraw:
			
			var Placed = await PlaceCardInPlayerHand(g)
			
			DeckP.OnCardDrawn()
			
			if (Placed):
				call_deferred("DoCardPlecementAnimation", g, DeckP.global_position)
			else:
				g.queue_free()


		
		return
	else :if (C.CStats is CardSpawn):
		var CardToSpawn = C.CStats.CardToSpawn
		
		UpdateEnergy(Energy, Energy - C.GetCost())
		var pos = C.global_position
		C.get_parent().remove_child(C)
		add_child(C)
		C.global_position = pos
		C.KillCard(0.5, true)
		
		var S = DeletableSoundGlobal.new()
		S.stream = RemoveCardSound
		S.autoplay = true
		add_child(S)
		S.volume_db = -10
		
		
		deck.Hand.erase(C.CStats)
		deck.DiscardPile.append(C.CStats)
		
		DrawSpecificCard(CardToSpawn)
		
		DiscardP.OnCardDiscarded(C.global_position + (C.size / 2))
		#if (Energy + resupplyamm > 10):
			#return
		
		
		return
	else : if (C.CStats is Deffensive and C.CStats.UseInstant):
		if (C.CStats.Shield):
			C.queue_free()
			deck.Hand.erase(C.CStats)
			deck.DiscardPile.append(C.CStats)
			UpdateEnergy(Energy, Energy - C.GetCost())
			HandleShield(ShipTurns[CurrentTurn], C.CStats)
			DiscardP.OnCardDiscarded(C.global_position + (C.size / 2))
			return
		else: if (C.CStats is Buff):
			C.queue_free()
			deck.Hand.erase(C.CStats)
			deck.DiscardPile.append(C.CStats)
			UpdateEnergy(Energy, Energy - C.GetCost())
			HandleBuff(ShipTurns[CurrentTurn], C.CStats)
			DiscardP.OnCardDiscarded(C.global_position + (C.size / 2))
			return

		else: if (C.CStats.FireExt):
			C.queue_free()
			deck.Hand.erase(C.CStats)
			deck.DiscardPile.append(C.CStats)
			UpdateEnergy(Energy, Energy - C.GetCost())
			HandleFireExtinguish(ShipTurns[CurrentTurn], C.CStats)
			DiscardP.OnCardDiscarded(C.global_position + (C.size / 2))
			return
			
	else:
		var Action : CardStats
		#if (C.CStats.SelectedOption != null):
			#Action = C.CStats.duplicate() as CardStats
			#Action.SelectedOption = C.CStats.SelectedOption
		#else:
		Action = C.CStats
		
		
		var CurrentShip = ShipTurns[CurrentTurn]
		if (!Action.AllowDuplicates and ActionList.ShipHasAction(CurrentShip, Action)):
			return
		
		var c = CardScene.instantiate() as Card

		
		c.SetCardStats(Action)
		
		
		var targets = await HandleTargets(Action, ShipTurns[CurrentTurn])

		if (targets.size() == 0):
			return
		
		UpdateEnergy(Energy, Energy - c.GetCost())
		
		#if (target != CurrentShip):
		
		for g in targets:
			var TargetViz = GetShipViz(g)
			c.TargetLocs.append(TargetViz.global_position + TargetViz.size / 2)
			
		c.connect("OnCardPressed", RemoveCard)
		for g in SelectedCardPlecement.get_children():
			if (g.get_child_count() == 0):
				g.add_child(c)
				break
		#c.Dissable()
		var ShipAction = CardFightAction.new()
		ShipAction.Action = Action
		ShipAction.Targets.append_array(targets)
		
		ActionList.AddAction(CurrentShip, ShipAction)
		
		call_deferred("DoCardPlecementAnimation", c, C.global_position)
		C.queue_free()

	#if (C.CStats is OffensiveCardStats):
	if (C.CStats.Consume):
		var ShipCards = ShipTurns[CurrentTurn].Cards
		ShipCards[C.CStats] -= 1
		if (ShipCards[C.CStats] == 0):
			ShipCards.erase(C.CStats)

	#if (C.CStats.SelectedOption != null):
		#if (C.CStats.SelectedOption.CauseConsumption):
			#var Ammo = ShipTurns[CurrentTurn].Ammo
			#Ammo[C.CStats.SelectedOption] -= 1
			#if (Ammo[C.CStats.SelectedOption] == 0):
				#Ammo.erase(C.CStats.SelectedOption)


	deck.Hand.erase(C.CStats)
	
	#DoCardPlecementAnimation(c, C.global_position)
	UpdateHandAmount(deck.Hand.size())
	#UpdateHandCards()
	#PerformAction(CurrentShip, ShipAction)

func RemoveCard(C : Card) -> void:
	if (SelectingTarget or EnemyPickingMove):
		return
	
	var D = PlayerDecks[ShipTurns[CurrentTurn]]
	
	if (D.Hand.size() == MaxCardsInHand):
		NotifyFullHand()
		return
	
	C.disconnect("OnCardPressed", RemoveCard)
	
	var S = DeletableSoundGlobal.new()
	S.stream = RemoveCardSound
	S.autoplay = true
	add_child(S)
	S.volume_db = -10

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

	#if (C.CStats.SelectedOption != null):
		#if (C.CStats.SelectedOption.CauseConsumption):
			#var Ammo = ShipTurns[CurrentTurn].Ammo
			#if (!Ammo.has(C.CStats.SelectedOption)):
				#Ammo[C.CStats.SelectedOption] = 1
			#else:
				#Ammo[C.CStats.SelectedOption] += 1

	var CurrentShip = ShipTurns[CurrentTurn]
	
	ActionList.RemoveActionFromShip(CurrentShip, C.CStats)
	#Actions[CurrentShip].erase(C.CStats)
	UpdateEnergy(Energy, Energy + C.GetCost())
	

	D.Hand.append(C.CStats)
	UpdateHandAmount(D.Hand.size())
	
	#UpdateHandCards()
	var c = CardScene.instantiate() as Card
	c.SetCardStats(C.CStats)
	c.connect("OnCardPressed", OnCardSelected)
	
	PlayerCardPlecement.add_child(c)

	call_deferred("DoCardPlecementAnimation", c, C.global_position)
	
	C.queue_free()

func UpdateEnergy(OldEnergy : float, NewEnergy : float) -> void:
	EnergyBar.UpdateAmmount(OldEnergy, NewEnergy)
	Energy = NewEnergy
	if (NewEnergy > max(OldEnergy, TurnEnergy)):
		EnergyBar.ChangeSegmentAmm(Energy)

func UpdateReserves(OldEnergy : float, NewEnergy : float) -> void:
	ReservesBar.UpdateAmmount(OldEnergy, NewEnergy)
	if (NewEnergy > Reserv):
		ReservesBar.ChangeSegmentAmm(NewEnergy)
	Reserv = NewEnergy
	

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
	
	if (!enemy):
		Stats.ShipIcon = load("res://Assets/Spaceship/Spaceship_top_2_Main Camera.png")
	else:
		Stats.ShipIcon = load("res://Assets/Spaceship/Spaceship_top_Main Camera.png")
		
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
	
	Stats.Cards[load("res://Resources/Cards/Energy.tres")] = 4
	Stats.Cards[load("res://Resources/Cards/EnergyReserve.tres")] = 3
	Stats.Cards[load("res://Resources/Cards/DrawDiscard.tres")] = 2
	
	Stats.Cards[load("res://Resources/Cards/Barrage/APBarrage.tres")] = 2
	Stats.Cards[load("res://Resources/Cards/Barrage/IncendiaryBarrage.tres")] = 2
	Stats.Cards[load("res://Resources/Cards/Barrage/ProxFuseBarrage.tres")] = 2
	Stats.Cards[load("res://Resources/Cards/Missile/ClusterMissile.tres")] = 2
	
		
	return Stats



func _on_deck_button_pressed() -> void:
	
	if (SelectingTarget or Energy < 1 or EnemyPickingMove):
		EnergyBar.NotifyNotEnough()
		return
	
	UpdateEnergy(Energy, Energy - 1)
	
	DrawCard()
	
	

var DeckHoverTween : Tween

func _on_deck_button_mouse_entered() -> void:
	#z_index = 1
	
	if (DeckHoverTween and DeckHoverTween.is_running()):
		DeckHoverTween.kill()
	
	DeckHoverTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).set_parallel(true)
	DeckHoverTween.tween_property(DeckP,"scale", Vector2(1.1, 1.1), 0.55)



func _on_deck_button_mouse_exited() -> void:
	#z_index = 0
	if (DeckHoverTween and DeckHoverTween.is_running()):
		DeckHoverTween.kill()
	DeckHoverTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel(true)
	DeckHoverTween.tween_property(DeckP,"scale", Vector2.ONE, 0.55)

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
	
	currentship.EnergyReserves = 0
	UpdateEnergy(Energy, Energy + Reserv)
	UpdateReserves(Reserv, 0)
	

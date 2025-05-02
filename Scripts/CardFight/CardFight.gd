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
@export var Cards : Array[CardStats]
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
@export var EnergyBar : SegmentedBar
@export var EnemyShipVisualPlecement : Control
@export var PlayerShipVisualPlecement : Control
@export var TargetSelect : CardFightTargetSelection
@export var CardSelect : CardFightDiscardSelection
@export var CardScrollContainer : ScrollContainer
@export var SelectedCardScrollContainer : ScrollContainer
@export var EnergyLabel : Label
@export var CardSelectContainer : Control
@export var ActionDeclaration : Control
@export var ShipSpacer : Control
@export var DeckButton : Button
@export var HandAmmountLabel : Label
@export_group("FightSettings")
@export var StartingCardAmm : int = 5
@export var MaxCombatants : int = 5
@export var TurnEnergy : int = 10
#Stats kept to show at the end screen
var DamageDone : float = 0
var DamageGot : float = 0
var DamageNeg : float = 0
var FundsToWin : int = 0

var Energy : int = 10

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

#Stored UI visualisation for ships
var ShipsViz : Array[CardFightShipViz2]



var ActionList = CardFightActionList.new()

var SelectingTarget : bool = false

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
	set_physics_process(false)
	
	EnergyBar.Init(TurnEnergy)
	
	
	for g in 10:
		EnemyReserves.append(GenerateRandomisedShip("en{0}".format([g]), true))

	for g in 10:
		PlayerReserves.append(GenerateRandomisedShip("pl{0}".format([g]), false))
	
	var EnReservesAmm : int = EnemyReserves.size()
	for g in min(MaxCombatants, EnReservesAmm):
		var NewCombatant = EnemyReserves.pick_random()
		EnemyCombatants.append(NewCombatant)
		EnemyReserves.erase(NewCombatant)
	var PlReservesAmm : int = PlayerReserves.size()
	for g in min(MaxCombatants, PlReservesAmm):
		var NewCombatant = PlayerReserves.pick_random()
		PlayerCombatants.append(NewCombatant)
		PlayerReserves.erase(NewCombatant)
		
	#Add all ships to turn array and sort them
	ShipTurns.append_array(PlayerCombatants)
	ShipTurns.append_array(EnemyCombatants)
	
	for g in ShipTurns:
		CreateShipVisuals(g)
	
	ShipTurns.sort_custom(speed_comparator)

	#Create the visualisation for each ship, basicly their stat holder
	
	CreateDecks()
	
	#print("Card fight initialised. {0} player ship(s) VS {1} enemy ship(s)".format([PlayerShips.size(), EnemyShips.size()]))
	
	DeckButton.visible = false
	EnergyBar.get_parent().visible = false
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
		CreateShipVisuals(NewCombatant)
		CreateDecks()
	if (EnemyCombatants.size() < MaxCombatants and EnemyReserves.size() > 0):
		var NewCombatant = EnemyReserves.pick_random()
		EnemyCombatants.append(NewCombatant)
		EnemyReserves.erase(NewCombatant)
		
		ShipTurns.append(NewCombatant)
		ShipTurns.sort_custom(speed_comparator)
		CreateShipVisuals(NewCombatant)

func CreateDecks() -> void:
	#Create the deck
	for g in PlayerCombatants:
		if PlayerDecks.keys().has(g):
			return
		var D = Deck.new()
		
		var ShipCards = g.Cards.keys()
		var ShipAmmo = g.Ammo.keys()
		
		for Crd : CardStats in ShipCards:
			var WType = Crd.WeapT
			var Amm = 0
			#if (Crd.Consume):
			Amm = g.Cards[Crd]
				
			for Dup in Amm:
				D.DeckPile.append(Crd)
			
			for Ammo in ShipAmmo:
				var am = Ammo as CardOption
				if (am.ComatibleWeapon == WType):
					#var c2 = CardScene.instantiate() as Card
					var Cstats2 = Crd.duplicate()
					Cstats2.SelectedOption = am
					var Amm2 = 0
					if (am.CauseConsumption):
						Amm2 = g.Ammo[Ammo]
					
					for Dup in Amm2:
						D.DeckPile.append(Cstats2)
		#Create Hand
		D.DeckPile.shuffle()
		for Hand in StartingCardAmm:
			var C = D.DeckPile.pick_random()
			D.Hand.append(C)
			D.DeckPile.erase(C)
		
		PlayerDecks[g] = D
					
func StoreContainerSize() -> void:
	CardSelectSize = CardSelectContainer.get_parent().size.y
	CardSelectContainer.get_parent().size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	#CardSelectContainer.custom_minimum_size.y = CardSelectSize
	CardSelectContainer.get_parent().visible = false
	
	ActionDeclaration.get_child(0).visible = false
	ActionDeclaration.get_child(0).modulate = Color(1,1,1,0)
	ActionDeclaration.visible = false

func DoActionDeclaration(ActionName : String) -> void:
	
	ShipSpacer.visible = true
	ActionDeclaration.visible = true
	ActionDeclaration.get_child(0).text = ActionName
	var Tw = create_tween()
	Tw.set_ease(Tween.EASE_OUT)
	Tw.set_trans(Tween.TRANS_QUAD)
	Tw.tween_property(ActionDeclaration, "custom_minimum_size", Vector2(650, 80), 0.5)
	
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
	Tw2.tween_property(ActionDeclaration.get_child(0), "modulate", Color(1,1,1,1), 0.5)
	await Tw2.finished
	
	await wait(1)
	
	var Tw3 = create_tween()
	Tw3.set_ease(Tween.EASE_OUT)
	Tw3.set_trans(Tween.TRANS_QUAD)
	Tw3.tween_property(ActionDeclaration.get_child(0), "modulate", Color(1,1,1,0), 0.5)
	await Tw3.finished
	
	ActionDeclaration.get_child(0).visible = false
	
	var Tw4 = create_tween()
	Tw4.set_ease(Tween.EASE_OUT)
	Tw4.set_trans(Tween.TRANS_QUAD)
	Tw4.tween_property(ActionDeclaration, "custom_minimum_size", Vector2(0, 80), 0.5)
	
	var OutSound = DeletableSoundGlobal.new()
	OutSound.stream = UIOutSound
	OutSound.autoplay = true
	OutSound.bus = "MapSounds"
	OutSound.pitch_scale = randf_range(0.9, 1.1)
	add_child(OutSound)
	
	await Tw4.finished
	ShipSpacer.visible = false
	ActionDeclaration.visible = false

func wait(secs : float) -> Signal:
	return get_tree().create_timer(secs).timeout

#function to sort battle ships based on their speed
static func speed_comparator(a, b):
	if a.Speed > b.Speed:
		return true  # -1 means 'a' should appear before 'b'
	elif a.Speed< b.Speed:
		return false  # 1 means 'b' should appear before 'a'
	return true
	
func CreateShipVisuals(BattleS : BattleShipStats) -> void:
	var t = ShipVizScene2.instantiate() as CardFightShipViz2
	#t.disabled = true
	#t.connect("pressed", ShipVizPressed.bind(BattleS))
	var Friendly = IsShipFriendly(BattleS)
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
	
	ShipsViz.append(t)

func ShipVizPressed(Ship : BattleShipStats) -> void:
	var Scene = CardFightShipInfoScene.instantiate() as CardFightShipInfo
	Scene.SetUpShip(Ship)
	add_child(Scene)

func GetShipViz(BattleS : BattleShipStats) -> CardFightShipViz2:
	var index = PlayerCombatants.find(BattleS)
	if (index == -1):
		index = EnemyCombatants.find(BattleS) + PlayerCombatants.size()
	return ShipsViz[index]
	
func UpdateShipStats(BattleS : BattleShipStats) -> void:
	var Friendly = IsShipFriendly(BattleS)
	GetShipViz(BattleS).SetStats(BattleS, Friendly)

#atm of a ship is on fire is stored in the UI. Should change #TODO
func ToggleFireToShip(BattleS : BattleShipStats, Fire : bool) -> void:
	GetShipViz(BattleS).ToggleFire(Fire)

func RemoveShip(Ship : BattleShipStats) -> void:
	var ShipViz = GetShipViz(Ship)
	ShipViz.ShipDestroyed()
	ShipsViz.erase(ShipViz)
	
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
	await DoActionDeclaration("Action Pick Phase")
	
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
	DeckButton.visible = true
	EnergyBar.get_parent().visible = true
	HandAmmountLabel.visible = true
	CurrentTurn = 0
	
	for Ship in ShipTurns:
		ActionList.AddShip(Ship)
		if (IsShipFriendly(Ship)):
			RestartCards()
			#var ATime = AtackTime.instantiate() as AtackTimer
			#CardSelectContainer.get_parent().add_child(ATime)
			#ATime.connect("Finished", PlayerActionSelectionEnded)
			await PlayerActionPickingEnded
			#ATime.queue_free()
		else:
			EnemyActionSelection(Ship)
			
		CurrentTurn += 1
		
	ClearCards()
	
	#CardSelectContainer.custom_minimum_size.y = CardSelectSize
	
	CardSelectContainer.get_child(0).visible = false
	
	var Tw = create_tween()
	Tw.set_ease(Tween.EASE_OUT)
	Tw.set_trans(Tween.TRANS_QUAD)
	Tw.tween_property(CardSelectContainer.get_parent(), "custom_minimum_size", Vector2(0,0), 0.5)
	await Tw.finished
	CardSelectContainer.get_parent().visible = false
	DeckButton.visible = false
	EnergyBar.get_parent().visible = false
	HandAmmountLabel.visible = false
	await DoActionDeclaration("Action Perform Phase")
	
	AnimationPlecement.visible = true
	for Ship in ShipTurns:
		var PerformedActions = await PerformActions(Ship)
		
		for ToBurn in PerformedActions:
			ActionList.RemoveActionFromShip(Ship, ToBurn.Action)
			#Actions[Ship].erase(ToBurn)
			
		if (GameOver):
			return

	await DoFireDamage()
	
	AnimationPlecement.visible = false
	
	if (GameOver):
		return
	
	RefundUnusedCards()
	ActionList.Clear()
	#Actions.clear()
	
	call_deferred("RunTurn")

func EnemyActionSelection(Ship : BattleShipStats) -> void:
	var EnemyEnergy = TurnEnergy
	
	if (GetShipViz(Ship).IsOnFire()):
		var ExtinguishAction
		for g in Cards:
			if (g.CardName == "Extinguish fires"):
				ExtinguishAction = g
		EnemyEnergy -= ExtinguishAction.Energy
		
		var Action = CardFightAction.new()
		Action.Action = ExtinguishAction
		Action.Targets.append(Ship)
		
		ActionList.AddAction(Ship, Action)
		#Actions[Ship].append(Action)
	
	var AvailableActions = Ship.Cards.duplicate()
	while (AvailableActions.size() > 0):
		var Action = (AvailableActions.keys().pick_random() as CardStats)
		
		if (!Action.AllowDuplicates and ActionList.ShipHasAction(Ship, Action)):
			AvailableActions.erase(Action)
			continue
			
		if (Action.CardName == "Extinguish fires" or Action.Energy > EnemyEnergy):
			AvailableActions.erase(Action)
			continue
		
		var SelectedAction = Action.duplicate()
		
		EnemyEnergy -= SelectedAction.Energy
		if (EnemyEnergy > 0 and SelectedAction.Options.size() > 0):
			SelectedAction.SelectedOption = SelectedAction.Options.pick_random()
			EnemyEnergy -= SelectedAction.SelectedOption.EnergyAdd
			
		AvailableActions.clear()
		AvailableActions = Ship.Cards.duplicate()
		
		var ShipAction = CardFightAction.new()
		ShipAction.Action = SelectedAction
		
		#TODO figure out better way to decide target
		if (Action is OffensiveCardStats):
			if (Action.AOE):
				ShipAction.Targets.append_array(PlayerCombatants)
			else:
				ShipAction.Targets.append(PlayerCombatants.pick_random())
		else:
			if (Action.AOE):
				ShipAction.Targets.append_array(EnemyCombatants)
			else: if (Action.CanBeUsedOnOther):
				ShipAction.Targets.append(EnemyCombatants.pick_random())
			else:
				ShipAction.Targets.append(Ship)
				
		ActionList.AddAction(Ship, ShipAction)

func PerformActions(Ship : BattleShipStats) -> Array[CardFightAction]:
	
	
	var ActionsToBurn : Array[CardFightAction]
	var Friendly = IsShipFriendly(Ship)
	var viz = GetShipViz(Ship)
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

			#if (Friendly):
				#Target = EnemyShips.pick_random()
			#else :
				#Target = PlayerShips.pick_random()
				
			ActionsToBurn.append(ShipAction)
			
			var Counter = Action.GetCounter()
			var HasDeff = false
			
			if (!Action.IsPorximityFuse()):
				for g in Targets:
					if (ActionList.ShipHasAction(g, Counter)):
						HasDeff = true
						break
			
			var anim = ActionAnim.instantiate() as CardOffensiveAnimation
			anim.DrawnLine = true
			AnimationPlecement.add_child(anim)
			AnimationPlecement.move_child(anim, 1)
			#anim.Originator = GetShipViz(Ship)
			var Vizs : Array[Control]
			for g in Targets:
				Vizs.append(GetShipViz(g))
				
			anim.DoOffensive(Action, HasDeff, Ship, Vizs, EnemyCombatants.has(Ship))
			
			await(anim.AnimationFinished)
			
			anim.visible = false
			anim.queue_free()
			
			if (HasDeff):
				for g in Targets:
					ActionList.RemoveActionFromShip(g, Counter)
				
				#print(Ship.Name + " has atacked " + Target.Name + " using " + Action.CardName + " but was countered")
				if (Friendly):
					DamageNeg += Action.GetDamage() * Ship.GetFirePower()
			else:
				for g in Targets:
					if (DamageShip(g, Action.GetDamage() * Ship.GetFirePower(), Action.CauseFire())):
						break
				
				#print(Ship.Name + " has atacked " + Target.Name + " using " + Action.CardName)
				
		else :if (Action is Deffensive):
			if (Action.CardName == "Extinguish fires" and viz.IsOnFire()):
				var anim = ActionAnim.instantiate() as CardOffensiveAnimation
				AnimationPlecement.add_child(anim)
				AnimationPlecement.move_child(anim, 1)
				anim.DoDeffensive(Action, [GetShipViz(Ship)], EnemyCombatants.has(Ship))
				await(anim.AnimationFinished)
				anim.visible = false
				anim.queue_free()
				viz.ToggleFire(false)
				ActionsToBurn.append(ShipAction)
				if (Action.Consume):
					var ShipCards = Ship.Cards
					ShipCards[Action] -= 1
					if (ShipCards[Action] == 0):
						ShipCards.erase(Action)

			else: if Action.CardName == "Shield Overcharge" or Action.CardName == "Shield Overcharge Team":
				var ShieldAmm : float
				if (Action.AOE):
					ShieldAmm = 10
				else:
					ShieldAmm = 20
				
				
				var anim = ActionAnim.instantiate() as CardOffensiveAnimation
				AnimationPlecement.add_child(anim)
				AnimationPlecement.move_child(anim, 1)
				
				var Vizs : Array[Control]
				for g in Targets:
					Vizs.append(GetShipViz(g))
					
				anim.DoDeffensive(Action, Vizs, EnemyCombatants.has(Ship))
				await(anim.AnimationFinished)
				anim.visible = false
				anim.queue_free()
				
				for T in Targets:
					ShieldShip(T, ShieldAmm * Action.Tier)
					
				ActionsToBurn.append(ShipAction)
			else: if Action.CardName == "Radar Atack":
				var anim = ActionAnim.instantiate() as CardOffensiveAnimation
				AnimationPlecement.add_child(anim)
				AnimationPlecement.move_child(anim, 1)
				
				var Vizs : Array[Control]
				for g in Targets:
					Vizs.append(GetShipViz(g))
					
				anim.DoDeffensive(Action, Vizs, EnemyCombatants.has(Ship))
				await(anim.AnimationFinished)
				anim.visible = false
				anim.queue_free()
				
				for T in Targets:
					BuffShip(T, 1 * Action.Tier)
					
				ActionsToBurn.append(ShipAction)

	for g in viz.get_parent().get_children():
		if (g != viz):
			var tw = create_tween()
			tw.set_ease(Tween.EASE_OUT)
			tw.set_trans(Tween.TRANS_QUAD)
			tw.tween_property(g, "custom_minimum_size", Vector2(0, 0), 0.2)
			await tw.finished
	
	
	
	return ActionsToBurn

func PerformAction(Pefrormer : BattleShipStats, ShipAction : CardFightAction) -> void:
	
	var Action = ShipAction.Action

	var Friendly = IsShipFriendly(Pefrormer)

	var viz = GetShipViz(Pefrormer)

	if (Action is OffensiveCardStats):
		
		var Target = ShipAction.Target
		
		if (!PlayerCombatants.has(Target) and !EnemyCombatants.has(Target)):
			#ship is dead
			return
			
		#if (Friendly):
			#Target = EnemyShips.pick_random()
		#else :
			#Target = PlayerShips.pick_random()
			
		#ActionsToBurn.append(ShipAction)
		
		var Counter = Action.GetCounter()
		var HasDeff = false
		
		
		if (!Action.IsPorximityFuse()):
			HasDeff = ActionList.ShipHasAction(Target, Counter)
		
		var anim = ActionAnim.instantiate() as CardOffensiveAnimation
		anim.DrawnLine = true
		AnimationPlecement.add_child(anim)
		AnimationPlecement.move_child(anim, 1)
		#anim.Originator = GetShipViz(Ship)
		anim.DoOffensive(Action, HasDeff, Pefrormer, [GetShipViz(Target)], EnemyCombatants.has(Pefrormer))
		
		await(anim.AnimationFinished)
		
		anim.visible = false
		anim.queue_free()
		
		if (HasDeff):
			ActionList.RemoveActionFromShip(Target, Counter)
			
			print(Pefrormer.Name + " has atacked " + Target.Name + " using " + Action.CardName + " but was countered")
			if (Friendly):
				DamageNeg += Action.GetDamage() * Pefrormer.GetFirePower()
		else:
			if (DamageShip(Target, Action.GetDamage() * Pefrormer.GetFirePower(), Action.CauseFire())):
				return
			
			print(Pefrormer.Name + " has atacked " + Target.Name + " using " + Action.CardName)
			
	else :if (Action is Deffensive):
		if (Action.CardName == "Extinguish fires" and viz.IsOnFire()):
			var anim = ActionAnim.instantiate() as CardOffensiveAnimation
			AnimationPlecement.add_child(anim)
			AnimationPlecement.move_child(anim, 1)
			anim.DoDeffensive(Action, [viz], Friendly)
			await(anim.AnimationFinished)
			anim.visible = false
			anim.queue_free()
			viz.ToggleFire(false)
			#ActionsToBurn.append(ShipAction)
			if (Action.Consume):
				var ShipCards = Pefrormer.Cards
				ShipCards[Action] -= 1
				if (ShipCards[Action] == 0):
					ShipCards.erase(Action)

		else: if Action.CardName == "Shield Overcharge" or Action.CardName == "Shield Overcharge Team":
			var ShieldAmm = 10
			
			
			var anim = ActionAnim.instantiate() as CardOffensiveAnimation
			AnimationPlecement.add_child(anim)
			AnimationPlecement.move_child(anim, 1)
			var Targets : Array[BattleShipStats]
			var TargetViz : Array[Control]
			if (Action.AOE):
				Targets = GetShipsTeam(Pefrormer)
				TargetViz = GetShipsTeamViz(Pefrormer)
			else:
				ShieldAmm = 20
				Targets = [Pefrormer]
				TargetViz = [GetShipViz(Pefrormer)]
				
			anim.DoDeffensive(Action, TargetViz, EnemyCombatants.has(Pefrormer))
			await(anim.AnimationFinished)
			anim.visible = false
			anim.queue_free()
			
			for T in Targets:
				ShieldShip(T, ShieldAmm * Action.Tier)
				
			#ActionsToBurn.append(ShipAction)
		else: if Action.CardName == "Radar Atack":
			var anim = ActionAnim.instantiate() as CardOffensiveAnimation
			AnimationPlecement.add_child(anim)
			AnimationPlecement.move_child(anim, 1)
			var Targets : Array[BattleShipStats]
			var TargetViz : Array[Control]
			if (Action.AOE):
				Targets = GetShipsTeam(Pefrormer)
				TargetViz = GetShipsTeamViz(Pefrormer)
			else:
				Targets = [Pefrormer]
				TargetViz = [GetShipViz(Pefrormer)]
				
			anim.DoDeffensive(Action, TargetViz, EnemyCombatants.has(Pefrormer))
			await(anim.AnimationFinished)
			anim.visible = false
			anim.queue_free()
			
			for T in Targets:
				BuffShip(T, 1 * Action.Tier)
				
			#ActionsToBurn.append(ShipAction)


func GetShipsTeam(Ship : BattleShipStats) -> Array[BattleShipStats]:
	var Team : Array[BattleShipStats]
	if (IsShipFriendly(Ship)):
		Team.append_array(PlayerCombatants)
	else:
		Team.append_array(EnemyCombatants)
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
	Ship.Shield = min(Ship.Hull / 2, Ship.Shield + Amm)
	UpdateShipStats(Ship)

func BuffShip(Ship : BattleShipStats, Amm : float) -> void:
	Ship.FirePowerBuff = Amm
	GetShipViz(Ship).ToggleDmgBuff(true)
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
			if (!ShipAction.Action.Consume):
				continue
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
		
	var deck = PlayerDecks[Ship]
	deck.DiscardPile.append(C)

func PlayerActionSelectionEnded() -> void:
	if (SelectingTarget):
		return
	GetShipViz(ShipTurns[CurrentTurn]).Dissable()
	PlayerActionPickingEnded.emit()

func RestartCards() -> void:
	ClearCards()
	
	EnergyBar.ChangeSegmentAmm(TurnEnergy)
	UpdateEnergy(0, TurnEnergy)
	UpdateHandCards()

	GetShipViz(ShipTurns[CurrentTurn]).Enable()
	
	CallAfter(DrawCard)
	
func CallAfter(Call : Callable, t : float = 1) -> void:
	await get_tree().create_timer(t).timeout
	Call.call()

func DrawCard() -> void:
	var D = PlayerDecks[ShipTurns[CurrentTurn]]
	
	if (D.DeckPile.size() == 0):
		D.DeckPile.append_array(D.DiscardPile)
		D.DiscardPile.clear()
	
	
	var C = D.DeckPile.pick_random()
	
	var c = CardScene.instantiate() as Card
	c.SetCardStats(C)
	c.connect("OnCardPressed", OnCardSelected)
	
	var Placed = await PlaceCardInPlayerHand(c)
	
	if (Placed):
		call_deferred("DoCardPlecementAnimation", c, DeckButton.global_position)
	else:
		c.queue_free()

func UpdateHandCards() -> void:
	for g in PlayerCardPlecement.get_children():
		for z in g.get_children():
			z.queue_free()
	

	var CharDeck = PlayerDecks[ShipTurns[CurrentTurn]]
	
	for ran in CharDeck.Hand:
		var c = CardScene.instantiate() as Card
		
		c.SetCardStats(ran)
		c.connect("OnCardPressed", OnCardSelected)
		
		for g in PlayerCardPlecement.get_children():
			if (g.get_child_count() == 0):
				g.add_child(c)
				break
		
		call_deferred("DoCardPlecementAnimation", c, DeckButton.global_position)
	
	UpdateHandAmount(CharDeck.Hand.size())

func PlaceCardInPlayerHand(C : Card) -> bool:
	var CanPlace : bool = false
	
	var CardsInHand : int = 0
	
	for g in PlayerCardPlecement.get_children():
		if (g.get_child_count() > 0):
			CardsInHand += 1
	#for g in SelectedCardPlecement.get_children():
		#if (g.get_child_count() > 0):
			#Cards += 1
	
	if (CardsInHand < 4):
		CanPlace = true
			
	var PlDeck = PlayerDecks[ShipTurns[CurrentTurn]]
	PlDeck.DeckPile.erase(C.CStats)
	
	if (CanPlace):
		PlDeck.Hand.append(C.CStats)
		for g in PlayerCardPlecement.get_children():
			if (g.get_child_count() == 0):
				g.add_child(C)
				break
	else:
		var Hand : Array[Card]
		for g in PlayerCardPlecement.get_children():
			if (g.get_child_count() > 0):
				Hand.append(g.get_child(0))
		#for g in SelectedCardPlecement.get_children():
			#if (g.get_child_count() > 0):
				#Hand.append(g.get_child(0))
				
		Hand.append(C)
		
		CardSelect.SetCards(Hand)
		SelectingTarget = true
		var ToDiscard : CardStats = await CardSelect.CardSelected
		SelectingTarget = false

		if (ToDiscard == C.CStats):
			PlDeck.DiscardPile.append(C.CStats)
			return false

		PlDeck.Hand.append(C.CStats)
		

		for g in PlayerCardPlecement.get_children():
			if (g.get_child_count() == 0):
				g.add_child(C)
				PlDeck.Hand.erase(ToDiscard)
				break
			else: if (g.get_child(0).CStats == ToDiscard):
				g.get_child(0).queue_free()
				PlDeck.DiscardPile.append(ToDiscard)
				g.add_child(C)
				PlDeck.Hand.erase(ToDiscard)
				break
		#for g in SelectedCardPlecement.get_children():
			#if (g.get_child_count() == 0):
				#continue
			#var Action = g.get_child(0).CStats as CardStats
			#if (Action == ToDiscard):
				#g.get_child(0).queue_free()
				#var CurrentShip = ShipTurns[CurrentTurn]
				#ActionList.RemoveActionFromShip(CurrentShip, ToDiscard)
				#
				#UpdateEnergy(Energy, Energy + g.get_child(0).GetCost())
				#
				#if (Action.Consume):
					#RefundCardToShip(Action, CurrentShip)
				#else: if (Action !=null or Action.SelectedOption.CauseConsumption):
					#RefundCardToShip(Action, CurrentShip)
				#else:
					#PlDeck.DiscardPile.append(ToDiscard)
				#break
	
	UpdateHandAmount(PlDeck.Hand.size())
	return true
	
func ClearCards() -> void:
	for g in PlayerCardPlecement.get_children():
		for z in g.get_children():
			z.free()

	for g in SelectedCardPlecement.get_children():
		for z in g.get_children():
			z.free()

func DoCardPlecementAnimation(C : Card, OriginalPos : Vector2) -> void:
	var c = CardScene.instantiate() as Card
	
	c.SetCardStats(C.CStats)
	c.TargetLocs = C.TargetLocs
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
	S.volume_db = - 10
	var PlecementTw = create_tween()
	PlecementTw.set_ease(Tween.EASE_OUT)
	PlecementTw.set_trans(Tween.TRANS_QUAD)
	#PlecementTw.tween_method(MoveCard.bind(OriginalPos, c, C), 0, 1, 0.4)
	PlecementTw.tween_property(c, "global_position", C.global_position, 0.4)
	C.visible = false
	await PlecementTw.finished
	c.queue_free()
	if (C != null):
		C.visible = true
	
#func MoveCard(Val : float, origpos : Vector2, C : Card, C2 : Card)  -> void:
	#C.global_position = lerp(origpos, C2.global_position, Val)

func OnCardSelected(C : Card) -> void:
	#var Minigame = FightGame.instantiate() as FightMinigame
	#add_child(Minigame)
	#var Resault = await Minigame.Ended
	#Minigame.queue_free()

	if (SelectingTarget):
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
		
		return
	
	else:
		var Action : CardStats
		if (C.CStats.SelectedOption != null):
			Action = C.CStats.duplicate() as CardStats
			Action.SelectedOption = C.CStats.SelectedOption
		else:
			Action = C.CStats
		
		
		var CurrentShip = ShipTurns[CurrentTurn]
		if (!Action.AllowDuplicates and ActionList.ShipHasAction(CurrentShip, Action)):
			return
		
		var c = CardScene.instantiate() as Card

		
		c.SetCardStats(Action)
		if (Energy < c.GetCost()):
			EnergyBar.NotifyNotEnough()
			c.queue_free()
			
			return
		
		var targets : Array[BattleShipStats]
		if (Action is OffensiveCardStats):
			if (EnemyCombatants.size() == 1):
				targets.append(EnemyCombatants[0])
			else: if Action.AOE:
				targets.append_array(EnemyCombatants)
			else:
				TargetSelect.SetEnemies(EnemyCombatants)
				SelectingTarget = true
				var Target = await TargetSelect.EnemySelected
				if (Target != null):
					targets.append(Target)
				SelectingTarget = false
		else:
			if (PlayerCombatants.size() == 1):
				targets.append(CurrentShip)
			else: if Action.AOE:
				targets.append_array(PlayerCombatants)
			else: if Action.CanBeUsedOnOther:
				TargetSelect.SetEnemies(PlayerCombatants)
				SelectingTarget = true
				var Target = await TargetSelect.EnemySelected
				if (Target != null):
					targets.append(Target)
				SelectingTarget = false
			else:
				targets.append(CurrentShip)
		if (targets.size() == 0):
			return
		#for g in C.CStats.Options:
			#if (g.OptionName == Option):
		#Action.SelectedOption = Option
		
		
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
		
	var Consumed : bool = false
	#if (C.CStats is OffensiveCardStats):
	if (C.CStats.Consume):
		var ShipCards = ShipTurns[CurrentTurn].Cards
		ShipCards[C.CStats] -= 1
		if (ShipCards[C.CStats] == 0):
			ShipCards.erase(C.CStats)
			
		Consumed = true
	if (C.CStats.SelectedOption != null):
		if (C.CStats.SelectedOption.CauseConsumption):
			var Ammo = ShipTurns[CurrentTurn].Ammo
			Ammo[C.CStats.SelectedOption] -= 1
			if (Ammo[C.CStats.SelectedOption] == 0):
				Ammo.erase(C.CStats.SelectedOption)
				
			Consumed = true

	deck.Hand.erase(C.CStats)
	if (!Consumed):
		deck.DiscardPile.append(C.CStats)
	#DoCardPlecementAnimation(c, C.global_position)
	UpdateHandAmount(deck.Hand.size())
	#UpdateHandCards()
	#PerformAction(CurrentShip, ShipAction)
	

func RemoveCard(C : Card) -> void:
	if (SelectingTarget):
		return
	
	var D = PlayerDecks[ShipTurns[CurrentTurn]]
	
	if (D.Hand.size() == 4):
		NotifyFullHand()
		return
	
	C.disconnect("OnCardPressed", RemoveCard)
	
	var S = DeletableSoundGlobal.new()
	S.stream = RemoveCardSound
	S.autoplay = true
	add_child(S)
	S.volume_db = -10
	
	var Consumed : bool = false
	
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
		Consumed = true
	if (C.CStats.SelectedOption != null):
		if (C.CStats.SelectedOption.CauseConsumption):
			var Ammo = ShipTurns[CurrentTurn].Ammo
			if (!Ammo.has(C.CStats.SelectedOption)):
				Ammo[C.CStats.SelectedOption] = 1
			else:
				Ammo[C.CStats.SelectedOption] += 1
				
			Consumed = true
	var CurrentShip = ShipTurns[CurrentTurn]
	
	ActionList.RemoveActionFromShip(CurrentShip, C.CStats)
	#Actions[CurrentShip].erase(C.CStats)
	UpdateEnergy(Energy, Energy + C.GetCost())
	

	D.Hand.append(C.CStats)
	UpdateHandAmount(D.Hand.size())
	if (!Consumed):
		D.DiscardPile.erase(C.CStats)
	
	#UpdateHandCards()
	var c = CardScene.instantiate() as Card
	c.SetCardStats(C.CStats)
	c.connect("OnCardPressed", OnCardSelected)

	for g in PlayerCardPlecement.get_children():
		if (g.get_child_count() == 0):
			g.add_child(c)
			break
	call_deferred("DoCardPlecementAnimation", c, C.global_position)
	
	C.queue_free()

func UpdateEnergy(OldEnergy : float, NewEnergy : float) -> void:
	EnergyBar.UpdateAmmount(OldEnergy, NewEnergy)
	Energy = NewEnergy
	if (Energy > TurnEnergy):
		EnergyBar.ChangeSegmentAmm(Energy)


var ScrollMomentum : float = 0

func _on_scroll_container_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		set_physics_process(true)
		ScrollMomentum += event.relative.x


var cloudtime : float = 0
func _process(delta: float) -> void:
	cloudtime += delta * SimulationManager.SimSpeed()
	$SubViewport/Control2/Clouds.material.set_shader_parameter("custom_time", cloudtime)

func _physics_process(delta: float) -> void:
	CardScrollContainer.scroll_horizontal -= ScrollMomentum
	ScrollMomentum = move_toward(ScrollMomentum, 0, delta * 500)
	if (ScrollMomentum == 0):
		set_physics_process(false)

func _on_selected_card_scroll_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		SelectedCardScrollContainer.scroll_vertical -= event.relative.y

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
	
	Stats.Cards[load("res://Resources/Cards/EnemyCards/EnemyBarrageLvl1.tres")] = 10
	Stats.Cards[load("res://Resources/Cards/Evasive.tres")] = 10
	Stats.Cards[load("res://Resources/Cards/Missile.tres")] = 10
	Stats.Cards[load("res://Resources/Cards/Flares.tres")] = 10
	Stats.Cards[load("res://Resources/Cards/ShieldOverChargeTeam.tres")] = 10
	Stats.Cards[load("res://Resources/Cards/RadarBuff.tres")] = 1
	
	if (!enemy):
		Stats.Cards[load("res://Resources/Cards/Energy.tres")] = 10
	
	Stats.Ammo[load("res://Resources/Cards/Barrage/Options/BarrageAPOption.tres")] = 10
	Stats.Ammo[load("res://Resources/Cards/Barrage/Options/BarrageFireOption.tres")] = 10
	Stats.Ammo[load("res://Resources/Cards/Barrage/Options/BarrageProxyOption.tres")] = 10
		
	return Stats



func _on_deck_button_pressed() -> void:
	
	if (SelectingTarget or Energy < 1):
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
	DeckHoverTween.tween_property(DeckButton,"scale", Vector2(1.1, 1.1), 0.55)



func _on_deck_button_mouse_exited() -> void:
	#z_index = 0
	if (DeckHoverTween and DeckHoverTween.is_running()):
		DeckHoverTween.kill()
	DeckHoverTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel(true)
	DeckHoverTween.tween_property(DeckButton,"scale", Vector2.ONE, 0.55)

func UpdateHandAmount(NewAmm : int) -> void:
	HandAmmountLabel.text = "In Hand \n{0}/4".format([NewAmm])

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

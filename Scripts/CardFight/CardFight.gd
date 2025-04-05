extends PanelContainer

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
@export var OffensiveCardPlecement : Control
#Plecement for any deffence cards player can play
@export var DeffensiveCardPlecement : Control
#Plecement for any cards player selects to play
@export var SelectedCardPlecement : Control
@export var AnimationPlecement : Control
@export var EnergyBar : ProgressBar
@export var EnemyShipVisualPlecement : Control
@export var PlayerShipVisualPlecement : Control
@export var TargetSelect : CardFightTargetSelection
@export var CardScrollContainer : ScrollContainer
@export var SelectedCardScrollContainer : ScrollContainer
@export var EnergyLabel : Label
@export var CardSelectContainer : Control
@export var ActionDeclaration : Control
#Stats kept to show at the end screen
var DamageDone : float = 0
var DamageGot : float = 0
var DamageNeg : float = 0
var FundsToWin : int = 0

var Energy : int = 10

#All ships are placed here based on their Speed stat, Once the turn starts this array is used for the turns
var ShipTurns : Array[BattleShipStats]

var CurrentTurn : int = 0

var PlayerShips : Array[BattleShipStats]

var EnemyShips : Array[BattleShipStats]

var ShipsViz : Array[CardFightShipViz]

#var Actions : Dictionary
var ActionList = CardFightActionList.new()

signal CardFightEnded(Survivors : Array[BattleShipStats])

#TODO
#ACTION WRAPPER
#WRAPPER THAT HOLDS IN ALL DATA FOR AN ACTION DONE

#TODO
#Find way to expand system to work with inventory items. DONE
#need to make sure that any armaments brought into the fight exist inside inventory. DONE
#armaments that can be used in map will be different to those used in card fight
#Card fight armaments will also be resupplied in same way in towns. DONE
#enemies need to have inventory of armaments to see what they can do in fight SEMI-DONE

var CardSelectSize : float

func _ready() -> void:
	for g in 1:
		EnemyShips.append(GenerateRandomisedShip("en{0}".format([g]), true))

	for g in 1:
		PlayerShips.append(GenerateRandomisedShip("pl{0}".format([g]), false))

	#Add all ships to turn array and sort them
	ShipTurns.append_array(PlayerShips)
	ShipTurns.append_array(EnemyShips)
	ShipTurns.sort_custom(speed_comparator)
	
	
	
	#Create the visualisation for each ship, basicly their stat holder
	for g in ShipTurns:
		CreateShipVisuals(g)
	
	print("Card fight initialised. {0} player ship(s) VS {1} enemy ship(s)".format([PlayerShips.size(), EnemyShips.size()]))
	
	call_deferred("StoreContainerSize")
	
	call_deferred("RunTurn")

func StoreContainerSize() -> void:
	CardSelectSize = CardSelectContainer.size.y
	CardSelectContainer.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	#CardSelectContainer.custom_minimum_size.y = CardSelectSize
	CardSelectContainer.visible = false
	
	ActionDeclaration.get_child(0).visible = false
	ActionDeclaration.get_child(0).modulate = Color(1,1,1,0)
	ActionDeclaration.visible = false

func DoActionDeclaration(ActionName : String) -> void:
	
	$VBoxContainer4/Control.visible = true
	ActionDeclaration.visible = true
	ActionDeclaration.get_child(0).text = ActionName
	var Tw = create_tween()
	Tw.set_ease(Tween.EASE_OUT)
	Tw.set_trans(Tween.TRANS_QUAD)
	Tw.tween_property(ActionDeclaration, "custom_minimum_size", Vector2(650, 80), 0.5)
	
	var InSound = DeletableSoundGlobal.new()
	InSound.stream = UIInSound
	InSound.autoplay = true
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
	add_child(OutSound)
	
	await Tw4.finished
	$VBoxContainer4/Control.visible = false
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
	var t = ShipVizScene.instantiate() as CardFightShipViz
	t.connect("pressed", ShipVizPressed.bind(BattleS))
	var Friendly = IsShipFriendly(BattleS)
	
	t.SetStats(BattleS, Friendly)
	
	if (Friendly):
		PlayerShipVisualPlecement.add_child(t)
	else :
		EnemyShipVisualPlecement.add_child(t)
	ShipsViz.append(t)

func ShipVizPressed(Ship : BattleShipStats) -> void:
	var Scene = CardFightShipInfoScene.instantiate() as CardFightShipInfo
	Scene.SetUpShip(Ship)
	add_child(Scene)

func GetShipViz(BattleS : BattleShipStats) -> CardFightShipViz:
	var index = ShipTurns.find(BattleS)
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
	PlayerShips.erase(Ship)
	EnemyShips.erase(Ship)

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
	
	CardSelectContainer.visible = true
	var Tw2 = create_tween()
	Tw2.set_ease(Tween.EASE_OUT)
	Tw2.set_trans(Tween.TRANS_QUAD)
	Tw2.tween_property(CardSelectContainer, "custom_minimum_size", Vector2(0,CardSelectSize), 0.5)
	await Tw2.finished
	
	CardSelectContainer.get_child(0).visible = true
	
	CurrentTurn = 0
	
	for Ship in ShipTurns:
		ActionList.AddShip(Ship)
		if (IsShipFriendly(Ship)):
			RestartCards()
			await PlayerActionPickingEnded
		else:
			EnemyActionSelection(Ship)
			
		CurrentTurn += 1
		
	ClearCards()
	
	#CardSelectContainer.custom_minimum_size.y = CardSelectSize
	
	CardSelectContainer.get_child(0).visible = false
	
	var Tw = create_tween()
	Tw.set_ease(Tween.EASE_OUT)
	Tw.set_trans(Tween.TRANS_QUAD)
	Tw.tween_property(CardSelectContainer, "custom_minimum_size", Vector2(0,0), 0.5)
	await Tw.finished
	CardSelectContainer.visible = false
	
	await DoActionDeclaration("Action Perform Phase")
	
	for Ship in ShipTurns:
		var PerformedActions = await PerformActions(Ship)
		
		for ToBurn in PerformedActions:
			ActionList.RemoveActionFromShip(Ship, ToBurn.Action)
			#Actions[Ship].erase(ToBurn)
			
		if (GameOver):
			return

	await DoFireDamage()
	
	if (GameOver):
		return

	
	
	RefundUnusedCards()
	ActionList.Clear()
	#Actions.clear()
	
	call_deferred("RunTurn")

func EnemyActionSelection(Ship : BattleShipStats) -> void:
	var EnemyEnergy = 10
	
	if (GetShipViz(Ship).IsOnFire()):
		var ExtinguishAction
		for g in Cards:
			if (g.CardName == "Extinguish fires"):
				ExtinguishAction = g
		EnemyEnergy -= ExtinguishAction.Energy
		
		var Action = CardFightAction.new()
		Action.Action = ExtinguishAction
		Action.Target = Ship
		
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
		ShipAction.Target = PlayerShips.pick_random()
		
		ActionList.AddAction(Ship, ShipAction)

func PerformActions(Ship : BattleShipStats) -> Array[CardFightAction]:
	var ActionsToBurn : Array[CardFightAction]
	var Friendly = IsShipFriendly(Ship)
	
	for z in ActionList.GetShipsActions(Ship):
		var ShipAction = z as CardFightAction
		var Action = ShipAction.Action
		if (Action is OffensiveCardStats):
			
			var Target = ShipAction.Target
			#if (Friendly):
				#Target = EnemyShips.pick_random()
			#else :
				#Target = PlayerShips.pick_random()
				
			ActionsToBurn.append(ShipAction)
			
			var Counter = Action.GetCounter()
			var HasDeff = false
			if (!Action.IsPorximityFuse()):
				HasDeff = ActionList.ShipHasAction(Target, Counter)
			
			var anim = ActionAnim.instantiate() as CardOffensiveAnimation
			anim.DrawnLine = true
			AnimationPlecement.add_child(anim)
			AnimationPlecement.move_child(anim, 1)
			#anim.Originator = GetShipViz(Ship)
			anim.DoOffensive(Action, HasDeff, Ship, [GetShipViz(Target)], EnemyShips.has(Ship))
			
			await(anim.AnimationFinished)
			
			anim.visible = false
			anim.queue_free()
			
			if (HasDeff):
				ActionList.RemoveActionFromShip(Target, Counter)
				
				print(Ship.Name + " has atacked " + Target.Name + " using " + Action.CardName + " but was countered")
				if (Friendly):
					DamageNeg += Action.GetDamage() * Ship.FirePower
			else:
				if (DamageShip(Target, Action.GetDamage() * Ship.FirePower, Action.CauseFire())):
					break
				
				print(Ship.Name + " has atacked " + Target.Name + " using " + Action.CardName)
				
		else :if (Action is Deffensive):
			var viz = GetShipViz(Ship)
			if (Action.CardName == "Extinguish fires" and viz.IsOnFire()):
				var anim = ActionAnim.instantiate() as CardOffensiveAnimation
				AnimationPlecement.add_child(anim)
				AnimationPlecement.move_child(anim, 1)
				anim.DoDeffensive(Action, Ship, EnemyShips.has(Ship))
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

			else: if Action.CardName == "Shield Overcharge":
				var anim = ActionAnim.instantiate() as CardOffensiveAnimation
				AnimationPlecement.add_child(anim)
				AnimationPlecement.move_child(anim, 1)
				anim.DoDeffensive(Action, Ship, EnemyShips.has(Ship))
				await(anim.AnimationFinished)
				anim.visible = false
				anim.queue_free()
				ShieldShip(Ship, 15)
				ActionsToBurn.append(ShipAction)

	return ActionsToBurn

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

	if (CauseFire and TrySetFire()):
			ToggleFireToShip(Ship, true)
	
	if (IsShipFriendly(Ship)):
		DamageGot += Dmg
	else:
		DamageDone += Dmg
	
	if (Ship.Hull <= 0):
		if (ShipDestroyed(Ship)):
			return true
	else:
		UpdateShipStats(Ship)
	return false

func ShieldShip(Ship : BattleShipStats, Amm : float) -> void:
	Ship.Shield = min(Ship.Hull / 2, Ship.Shield + Amm)
	UpdateShipStats(Ship)

func IsShipFriendly(Ship : BattleShipStats) -> bool:
	return PlayerShips.has(Ship)

func TrySetFire() -> bool:
	randomize()
	var random_value = randf()
	return random_value < 0.5

# RETURN TRUE IF FIGHT IS OVER
func ShipDestroyed(Ship : BattleShipStats) -> bool:
	if (EnemyShips.has(Ship)):
		FundsToWin += Ship.Funds
	
	RemoveShip(Ship)
	
	var EnemiesDead = GetFightingUnitAmmount(EnemyShips) == 0
	var PlayerDead = GetFightingUnitAmmount(PlayerShips) == 0
	
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
	Survivors.append_array(PlayerShips)
	Survivors.append_array(EnemyShips)

	CardFightEnded.emit(Survivors)


#Refunds cards that consume inventory items if the card wasnt used in the end
func RefundUnusedCards() -> void:
	for Ship in PlayerShips:
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

func PlayerActionSelectionEnded() -> void:
	ShipsViz[CurrentTurn].Dissable()
	PlayerActionPickingEnded.emit()

func RestartCards() -> void:
	ClearCards()
	Energy = 10
	UpdateEnergy()
	var CharCards = ShipTurns[CurrentTurn].Cards
	var CharAmmo = ShipTurns[CurrentTurn].Ammo
	for g in CharCards.keys():
		var c = CardScene.instantiate() as Card
		var WType = g.WeapT
		var PossibleOptions : Array[CardOption] = []
		for Ammo in CharAmmo:
			var am = Ammo as CardOption
			if (am.ComatibleWeapon == WType):
				PossibleOptions.append(am)
		c.SetCardStats(g, PossibleOptions)
		c.connect("OnCardPressed", OnCardSelected)
		if (g is OffensiveCardStats):
			OffensiveCardPlecement.add_child(c)
		else :
			DeffensiveCardPlecement.add_child(c)
	ShipsViz[CurrentTurn].Enable()

func UpdateHandCards() -> void:
	for g in OffensiveCardPlecement.get_children():
		g.queue_free()
	for g in DeffensiveCardPlecement.get_children():
		g.queue_free()
	var CharCards = ShipTurns[CurrentTurn].Cards
	var CharAmmo = ShipTurns[CurrentTurn].Ammo
	for g in CharCards.keys():
		var c = CardScene.instantiate() as Card
		var WType = g.WeapT
		var PossibleOptions : Array[CardOption] = []
		for Ammo in CharAmmo:
			var am = Ammo as CardOption
			if (am.ComatibleWeapon == WType):
				PossibleOptions.append(am)
		c.SetCardStats(g, PossibleOptions)
		c.connect("OnCardPressed", OnCardSelected)
		if (g is OffensiveCardStats):
			OffensiveCardPlecement.add_child(c)
		else :
			DeffensiveCardPlecement.add_child(c)

func ClearCards() -> void:
	for g in OffensiveCardPlecement.get_children():
		g.queue_free()
	for g in DeffensiveCardPlecement.get_children():
		g.queue_free()
	for g in SelectedCardPlecement.get_children():
		for z in g.get_children():
			z.queue_free()

func DoCardPlecementAnimation(C : Card, OriginalPos : Vector2) -> void:
	var c = CardScene.instantiate() as Card

	c.SetCardStats(C.CStats, [])
	c.TargetLoc = C.TargetLoc
	$Control.add_child(c)
	c.global_position = OriginalPos
	
	var S = DeletableSoundGlobal.new()
	S.stream = CardPlecementSound
	S.autoplay = true
	add_child(S)
	S.volume_db = - 10
	var PlecementTw = create_tween()
	PlecementTw.set_ease(Tween.EASE_OUT)
	PlecementTw.set_trans(Tween.TRANS_QUAD)
	PlecementTw.tween_property(c, "global_position", C.global_position, 0.4)
	C.visible = false
	await PlecementTw.finished
	c.queue_free()
	C.visible = true
	

func OnCardSelected(C : Card, Option : CardOption) -> void:
	var Action = C.CStats.duplicate() as CardStats
	var CurrentShip = ShipTurns[CurrentTurn]
	if (!Action.AllowDuplicates and ActionList.ShipHasAction(CurrentShip, Action)):
		return
	
	var target
	if (Action is OffensiveCardStats):
		if (EnemyShips.size() == 1):
			target = EnemyShips[0]
		else:
			TargetSelect.SetEnemies(EnemyShips)
			$VBoxContainer4/PanelContainer2.visible = false
			target = await TargetSelect.EnemySelected
			$VBoxContainer4/PanelContainer2.visible = true
	else:
		target = CurrentShip
	#for g in C.CStats.Options:
		#if (g.OptionName == Option):
	Action.SelectedOption = Option
	var c = CardScene.instantiate() as Card
	if (Option != null):
		c.SetCardStats(Action, [Option])
	else:
		c.SetCardStats(Action, [])
	if (Energy < c.GetCost()):
		return
	Energy -= c.GetCost()
	
	#if (target != CurrentShip):
	var TargetViz = GetShipViz(target)
	c.TargetLoc = TargetViz.global_position + TargetViz.size / 2
		
	c.connect("OnCardPressed", RemoveCard)
	for g in SelectedCardPlecement.get_children():
		if (g.get_child_count() == 0):
			g.add_child(c)
			break
	#c.Dissable()
	
	var ShipAction = CardFightAction.new()
	ShipAction.Action = Action
	ShipAction.Target = target
	
	ActionList.AddAction(CurrentShip, ShipAction)
	
	#if (C.CStats is OffensiveCardStats):
	if (C.CStats.Consume):
		var ShipCards = ShipTurns[CurrentTurn].Cards
		ShipCards[C.CStats] -= 1
		if (ShipCards[C.CStats] == 0):
			ShipCards.erase(C.CStats)
	if (Option != null):
		if (Option.CauseConsumption):
			var Ammo = ShipTurns[CurrentTurn].Ammo
			Ammo[Option] -= 1
			if (Ammo[Option] == 0):
				Ammo.erase(Option)
				
	#DoCardPlecementAnimation(c, C.global_position)
	call_deferred("DoCardPlecementAnimation", c, C.global_position)
	UpdateEnergy()
	UpdateHandCards()
	
	

func RemoveCard(C : Card, _Option : CardOption) -> void:
	var S = DeletableSoundGlobal.new()
	S.stream = RemoveCardSound
	S.autoplay = true
	add_child(S)
	S.volume_db = -10
	
	C.KillCard()
	#if (C.CStats is OffensiveCardStats):
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

	if (C.CStats.SelectedOption != null):
		if (C.CStats.SelectedOption.CauseConsumption):
			var Ammo = ShipTurns[CurrentTurn].Ammo
			if (!Ammo.has(C.CStats.SelectedOption)):
				Ammo[C.CStats.SelectedOption] = 1
			else:
				Ammo[C.CStats.SelectedOption] += 1
			
	var CurrentShip = ShipTurns[CurrentTurn]
	
	ActionList.RemoveActionFromShip(CurrentShip, C.CStats)
	#Actions[CurrentShip].erase(C.CStats)
	Energy += C.GetCost()
	UpdateEnergy()
	UpdateHandCards()

var EnergyBarTween : Tween

func UpdateEnergy() -> void:
	if (is_instance_valid(EnergyBarTween)):
		EnergyBarTween.kill()
	EnergyBarTween = create_tween()
	EnergyBarTween.set_ease(Tween.EASE_OUT)
	EnergyBarTween.set_trans(Tween.TRANS_QUAD)
	EnergyBarTween.tween_method(UpdateEnergyBar, EnergyBar.value, Energy, 0.5)


func UpdateEnergyBar(NewVal : float) -> void:
	EnergyBar.value = NewVal
	EnergyLabel.text = var_to_str(roundi(NewVal)) + " / 10"

#func PlayOffensiveAction(SourcePos : Vector2, TargetPos : Vector2, Countered : bool) -> void:
	#pass

func _on_scroll_container_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		CardScrollContainer.scroll_vertical -= event.relative.y

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
	
	Stats.Cards[load("res://Resources/Cards/EnemyCards/EnemyBarrageLvl1.tres")] = 1
	Stats.Cards[load("res://Resources/Cards/Evasive.tres")] = 1
		
	return Stats

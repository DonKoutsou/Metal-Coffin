extends PanelContainer

class_name Card_Fight

@export var CardScene : PackedScene
@export var ShipVizScene : PackedScene
@export var Cards : Array[CardStats]
#Animation of the atack
@export var ActionAnim : PackedScene
#Scene that shows the stats of the fight
@export var EndScene : PackedScene

@export_group("Plecement Referances")
#Plecement for any atack cards player can play
@export var OffensiveCardPlecement : HBoxContainer
#Plecement for any deffence cards player can play
@export var DeffensiveCardPlecement : HBoxContainer
#Plecement for any cards player selects to play
@export var SelectedCardPlecement : HBoxContainer
@export var AnimationPlecement : Control
@export var EnergyBar : ProgressBar
@export var EnemyShipVisualPlecement : Control
@export var PlayerShipVisualPlecement : Control

#Stats kept to show at the end screen
var DamageDone : float = 0
var DamageGot : float = 0
var DamageNeg : float = 0
var FundsToWin : float = 0

var Energy : int = 4

#All ships are placed here based on their Speed stat, Once the turn starts this array is used for the turns
var ShipTurns : Array[BattleShipStats]

var CurrentTurn : int = 0

var PlayerShips : Array[BattleShipStats]

var EnemyShips : Array[BattleShipStats]

var ShipsViz : Array[CardFightShipViz]

var Actions : Dictionary

signal CardFightEnded(Survivors : Array[BattleShipStats])

#TODO
#Find way to expand system to work with inventory items. DONE
#need to make sure that any armaments brought into the fight exist inside inventory. DONE
#armaments that can be used in map will be different to those used in card fight
#Card fight armaments will also be resupplied in same way in towns. DONE
#enemies need to have inventory of armaments to see what they can do in fight SEMI-DONE

func _ready() -> void:
	#Add all ships to turn array and sort them
	ShipTurns.append_array(PlayerShips)
	ShipTurns.append_array(EnemyShips)
	ShipTurns.sort_custom(speed_comparator)
	
	for g in EnemyShips:
		FundsToWin += g.Funds
	
	#Create the visualisation for each ship, basicly their stat holder
	for g in ShipTurns:
		CreateShipVisuals(g)
	
	print("Card fight initialised. {0} player ship(s) VS {1} enemy ship(s)".format([PlayerShips.size(), EnemyShips.size()]))
	
	RunTurn()

#function to sort battle ships based on their speed
static func speed_comparator(a, b):
	if a.Speed > b.Speed:
		return true  # -1 means 'a' should appear before 'b'
	elif a.Speed< b.Speed:
		return false  # 1 means 'b' should appear before 'a'
	return true
	
func CreateShipVisuals(BattleS : BattleShipStats) -> void:
	var t = ShipVizScene.instantiate() as CardFightShipViz
	var Friendly = IsShipFriendly(BattleS)
	
	t.SetStats(BattleS, Friendly)
	
	if (Friendly):
		PlayerShipVisualPlecement.add_child(t)
	else :
		EnemyShipVisualPlecement.add_child(t)
	ShipsViz.append(t)

func GetShipViz(BattleS : BattleShipStats) -> CardFightShipViz:
	var index = ShipTurns.find(BattleS)
	return ShipsViz[index]
	
func UpdateShipStats(BattleS : BattleShipStats) -> void:
	var Friendly = IsShipFriendly(BattleS)
	GetShipViz(BattleS).SetStats(BattleS, Friendly)

func ToggleFireToShip(BattleS : BattleShipStats, Fire : bool) -> void:
	GetShipViz(BattleS).ToggleFire(Fire)

func RemoveShip(Ship : BattleShipStats) -> void:
	var ShipViz = GetShipViz(Ship)
	ShipViz.ShipDestroyed()
	ShipsViz.erase(ShipViz)

	Actions.erase(Ship)
	ShipTurns.erase(Ship)
	PlayerShips.erase(Ship)
	EnemyShips.erase(Ship)

#/////////////////////////////////////////////////
#PHASES
var GameOver : bool = false

signal PlayerActionPickingEnded

func RunTurn() -> void:
	CurrentTurn = 0
	
	for Ship in ShipTurns:
		Actions[Ship] = []
		if (IsShipFriendly(Ship)):
			RestartCards()
			await PlayerActionPickingEnded
		else:
			EnemyActionSelection(Ship)
			
		CurrentTurn += 1
		
	ClearCards()
	
	$VBoxContainer4/VBoxContainer4.visible = false
	
	for Ship in Actions:
		var PerformedActions = await PerformActions(Ship)
		
		for ToBurn in PerformedActions:
			Actions[Ship].erase(ToBurn)
			
		if (GameOver):
			return

	await DoFireDamage()
	
	if (GameOver):
		return
		
	$VBoxContainer4/VBoxContainer4.visible = true
	
	RefundUnusedCards()
	Actions.clear()
	
	call_deferred("RunTurn")

func EnemyActionSelection(Ship : BattleShipStats) -> void:
	var EnemyEnergy = 4
	
	if (GetShipViz(Ship).IsOnFire()):
		var ExtinguishAction
		for g in Cards:
			if (g.CardName == "Extinguish fires"):
				ExtinguishAction = g
		EnemyEnergy -= ExtinguishAction.Energy
		Actions[Ship].append(ExtinguishAction)
	
	while (EnemyEnergy > 0):
		var Action = (Cards.pick_random() as CardStats).duplicate()
		if (!Action.AllowDuplicates and Actions[Ship].has(Action)):
			continue
		if (Action.CardName == "Extinguish fires"):
			continue
		EnemyEnergy -= Action.Energy
		if (EnemyEnergy > 0 and Action.Options.size() > 0):
			Action.SelectedOption = Action.Options.pick_random()
			EnemyEnergy -= Action.SelectedOption.EnergyAdd
		Actions[Ship].append(Action)


func PerformActions(Ship : BattleShipStats) -> Array[CardStats]:
	var ActionsToBurn : Array[CardStats]
	var Friendly = IsShipFriendly(Ship)
	
	for z in Actions[Ship]:
		var Action = z as CardStats
		
		if (Action is OffensiveCardStats):
			var Target
			if (Friendly):
				Target = EnemyShips.pick_random()
			else :
				Target = PlayerShips.pick_random()
				
			ActionsToBurn.append(Action)
			
			var Counter = Action.GetCounter()
			var HasDeff = ShipHasDeffence(Target, Counter)
			
			var anim = ActionAnim.instantiate() as CardOffensiveAnimation
			anim.DrawnLine = true
			AnimationPlecement.add_child(anim)
			AnimationPlecement.move_child(anim, 1)
			anim.DoOffensive(Action, HasDeff, Ship, Target, EnemyShips.has(Ship))
			
			await(anim.AnimationFinished)
			
			if (HasDeff):
				Actions[Target].erase(Counter)
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
				viz.ToggleFire(false)
				if (Action.Consume):
					var ShipCards = Ship.Cards
					ShipCards[Action] -= 1
					if (ShipCards[Action] == 0):
						ShipCards.erase(Action)
				ActionsToBurn.append(Action)
				
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
			if (DamageShip(g, 10)):
				break
#////////////////////////////////////////////////////////////////////////////

func ShipHasDeffence(Ship : BattleShipStats, NeededDef : CardStats) -> bool:
	if (NeededDef == null):
		return false
	var HasDeff = false
	for Ac in Actions[Ship]:
		var TargAction = Ac as CardStats
		if (TargAction.CardName == NeededDef.CardName):
			Actions[Ship].erase(Ac)
			HasDeff = true
			break
	return HasDeff

# RETURN TRUE IF FIGHT IS OVER
func DamageShip(Ship : BattleShipStats, Amm : float, CauseFire : bool = false) -> bool:
	Ship.Hull -= Amm

	if (CauseFire and TrySetFire()):
			ToggleFireToShip(Ship, true)
	
	if (IsShipFriendly(Ship)):
		DamageGot += Amm
	else:
		DamageDone += Amm
	
	if (Ship.Hull <= 0):
		if (ShipDestroyed(Ship)):
			return true
	else:
		UpdateShipStats(Ship)
	return false

func IsShipFriendly(Ship : BattleShipStats) -> bool:
	return PlayerShips.has(Ship)

func TrySetFire() -> bool:
	randomize()
	var random_value = randf()
	return random_value < 0.5

# RETURN TRUE IF FIGHT IS OVER
func ShipDestroyed(Ship : BattleShipStats) -> bool:
	RemoveShip(Ship)
	
	var EnemiesDead = EnemyShips.size() == 0
	var PlayerDead = PlayerShips.size() == 0
	
	if (EnemiesDead or PlayerDead):
		RefundUnusedCards()
		GameOver = true
		call_deferred("OnFightEnded", EnemiesDead)
		return true
		
	return false

# CALLED AT THE END. SHOWS ENDSCREEN WITH DATA COLLECTED AND WAITS FOR PLAYER 
func OnFightEnded(Won : bool) -> void:
	var End = EndScene.instantiate() as CardFightEndScene
	End.SetData(Won, FundsToWin, DamageDone, DamageGot, DamageNeg)
	add_child(End)
	await End.ContinuePressed
	if (Won):
		CardFightEnded.emit(PlayerShips)
	else:
		CardFightEnded.emit(EnemyShips)
	queue_free()

#Refunds cards that consume inventory items if the card wasnt used in the end
func RefundUnusedCards() -> void:
	for Ship in PlayerShips:
		var Acts = Actions[Ship]
		for z in Acts:
			var Action = z as CardStats
			if (!Action.Consume):
				continue
			RefundCardToShip(Action, Ship)


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
	Energy = 4
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
		g.queue_free()

func OnCardSelected(C : Card, Option : CardOption) -> void:
	var Action = C.CStats.duplicate() as CardStats
	var CurrentShip = ShipTurns[CurrentTurn]
	if (!Action.AllowDuplicates and Actions[CurrentShip].has(Action)):
		return
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
	
	c.connect("OnCardPressed", RemoveCard)
	SelectedCardPlecement.add_child(c)
	Actions[CurrentShip].append(Action)
	
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
	UpdateEnergy()
	UpdateHandCards()

func RemoveCard(C : Card, _Option : CardOption) -> void:
	C.queue_free()
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
	Actions[CurrentShip].erase(C.CStats)
	Energy += C.GetCost()
	UpdateEnergy()
	UpdateHandCards()
	
func UpdateEnergy() -> void:
	EnergyBar.value = Energy
	EnergyBar.get_child(0).text = var_to_str(Energy) + " / 4"

#func PlayOffensiveAction(SourcePos : Vector2, TargetPos : Vector2, Countered : bool) -> void:
	#pass

func _on_scroll_container_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		$VBoxContainer4/VBoxContainer4/ScrollContainer.scroll_horizontal -= event.relative.x

func GenerateRandomisedShip(Name : String, enemy : bool) -> BattleShipStats:
	var Stats = BattleShipStats.new()
	Stats.Name = Name
	Stats.FirePower = randf_range(0.5, 3)
	Stats.Hull = randf_range(10, 800)
	Stats.Speed = randf_range(0.5, 3)
	if (!enemy):
		Stats.ShipIcon = load("res://Assets/Spaceship/Spaceship_top_2_Main Camera.png")
	else:
		Stats.ShipIcon = load("res://Assets/Spaceship2/Spaceship2Top_Main Camera 3.png")
	return Stats

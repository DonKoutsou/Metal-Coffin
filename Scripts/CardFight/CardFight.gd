extends PanelContainer

class_name Card_Fight

@export var CardScene : PackedScene
@export var ShipVizScene : PackedScene
@export var Cards : Array[CardStats]
@export var ActionAnim : PackedScene
@export var EndScene : PackedScene
@onready var offensive_card_plecements: HBoxContainer = $VBoxContainer4/VBoxContainer4/VBoxContainer3/OffensiveCardPlecements
@onready var deffensive_card_plecements: HBoxContainer = $VBoxContainer4/VBoxContainer4/VBoxContainer3/DeffensiveCardPlecements
@onready var selected_card_plecements: HBoxContainer = $VBoxContainer4/VBoxContainer4/HBoxContainer2/SelectedCardPlecements

var DamageDone : float = 0
var DamageGot : float = 0
var DamageNeg : float = 0
var FundsToWin : float = 0

var Energy : int = 4

var ShipTurns : Array[BattleShipStats]

var CurrentTurn : int = 0

var PlayerShips : Array[BattleShipStats]

var EnemyShips : Array[BattleShipStats]

var ShipsViz : Array[CardFightShipViz]

var Actions : Dictionary

signal CardFightEnded(Survivors : Array[BattleShipStats])

#TODO
#Find way to expand system to work with inventory items.
#need to make sure that any armaments brought into the fight exist inside inventory.
#armaments that can be used in map will be different to those used in card fight
#Card fight armaments will also be resupplied in same way in towns.
#enemies need to have inventory of armaments to see what they can do in fight

func _ready() -> void:
	#for g in 3:
		#PlayerShips.append(GenerateRandomisedShip("Player" + var_to_str(g), false))
	#for g in 3:
		#EnemyShips.append(GenerateRandomisedShip("Enemy" + var_to_str(g), true))
	
	ShipTurns.append_array(PlayerShips)
	ShipTurns.append_array(EnemyShips)
	ShipTurns.sort_custom(speed_comparator)
	for g in EnemyShips:
		FundsToWin += g.Funds
	#for g in PlayerShips:
		#AddShip(g, true)
	for g in ShipTurns:
		AddShip(g)
	print("init done")
	StartActionPickPhase()

#function to sort battle ships based on their speed
static func speed_comparator(a, b):
	if a.Speed > b.Speed:
		return true  # -1 means 'a' should appear before 'b'
	elif a.Speed< b.Speed:
		return false  # 1 means 'b' should appear before 'a'
	return true
	
func AddShip(BattleS : BattleShipStats) -> void:
	var t = ShipVizScene.instantiate() as CardFightShipViz
	var Friendly : bool = PlayerShips.has(BattleS)
	t.SetStats(BattleS, Friendly)
	if (Friendly):
		$VBoxContainer4/VBoxContainer2.add_child(t)
	else :
		$VBoxContainer4/VBoxContainer.add_child(t)
	ShipsViz.append(t)

func GetShipViz(BattleS : BattleShipStats) -> CardFightShipViz:
	var index = ShipTurns.find(BattleS)
	return ShipsViz[index]
	
func UpdateShipStats(BattleS : BattleShipStats) -> void:
	var Friendly : bool = PlayerShips.has(BattleS)
	var index = ShipTurns.find(BattleS)
	ShipsViz[index].SetStats(BattleS, Friendly)

func ToggleFireToShip(BattleS : BattleShipStats, Fire : bool) -> void:
	#var Friendly : bool = PlayerShips.has(BattleS)
	var index = ShipTurns.find(BattleS)
	ShipsViz[index].ToggleFire(Fire)

func RemoveShip(Ship : BattleShipStats) -> void:
	var index = ShipTurns.find(Ship)
	ShipsViz[index].ShipDestroyed()
	ShipsViz.remove_at(index)
	ShipTurns.erase(Ship)
	PlayerShips.erase(Ship)
	EnemyShips.erase(Ship)

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

func StartActionPickPhase() -> void:
	CurrentTurn = 0
	NextShipActionPick()

func EndActionPickPhase() -> void:
	ClearCards()
	StartActionPerformPhase()

func StartActionPerformPhase() -> void:
	$VBoxContainer4/VBoxContainer4.visible = false
	for g in Actions:
		var Ship = g as BattleShipStats
		if (Ship.Hull <= 0):
			continue
		for z in Actions[Ship]:
			var Action = z as CardStats
			if (Action is OffensiveCardStats):
				var friendly = PlayerShips.has(Ship)
				var Target
				if (friendly):
					Target = EnemyShips.pick_random()
				else :
					Target = PlayerShips.pick_random()
				
				
				var HasDeff = false
				var DefName = Action.CounteredBy.CardName
				for Ac in Actions[Target]:
					var TargAction = Ac as CardStats
					if (TargAction.CardName == DefName):
						Actions[Target].erase(Ac)
						HasDeff = true
						break
				
				var anim = ActionAnim.instantiate() as CardOffensiveAnimation
				anim.DrawnLine = true
				var Def
				if (HasDeff):
					Def = Action.CounteredBy
				$VBoxContainer4.add_child(anim)
				$VBoxContainer4.move_child(anim, 1)
				anim.DoOffensive(Action, Def, Ship, Target, EnemyShips.has(Ship))
				await(anim.AnimationFinished)
				
				if (HasDeff):
					Actions[Target].erase(Action.CounteredBy)
					print(Ship.Name + " has atacked " + Target.Name + " using " + Action.CardName + " but was countered")
					if (PlayerShips.has(Ship)):
						DamageNeg += Action.GetDamage() * Ship.FirePower
				else:
					if (Action.CauseFire()):
						if (TrySetFire()):
							ToggleFireToShip(Target, true)
					Target.Hull -= Action.GetDamage() * Ship.FirePower
					
					if (PlayerShips.has(Ship)):
						DamageDone += Action.GetDamage() * Ship.FirePower
					else:
						DamageGot += Action.GetDamage() * Ship.FirePower
					
					if (Target.Hull <= 0):
						if (await ShipDestroyed(Target)):
							return
					else:
						UpdateShipStats(Target)
					
					print(Ship.Name + " has atacked " + Target.Name + " using " + Action.CardName)
			if (Action is Deffensive):
				var viz = GetShipViz(Ship)
				if (Action.CardName == "Extinguish fires" and viz.IsOnFire()):
					var anim = ActionAnim.instantiate() as CardOffensiveAnimation
					$VBoxContainer4.add_child(anim)
					$VBoxContainer4.move_child(anim, 1)
					anim.DoDeffensive(Action, Ship, EnemyShips.has(Ship))
					await(anim.AnimationFinished)
					viz.ToggleFire(false)
	for g in ShipTurns:
		var viz = GetShipViz(g)
		if (viz.IsOnFire()):
			var anim = ActionAnim.instantiate() as CardOffensiveAnimation
			$VBoxContainer4.add_child(anim)
			$VBoxContainer4.move_child(anim, 1)
			anim.DoFire(g, EnemyShips.has(g))
			await(anim.AnimationFinished)
			g.Hull -= 10
			if (g.Hull <= 0):
				if (await ShipDestroyed(g)):
					return
			else:
				UpdateShipStats(g)
	$VBoxContainer4/VBoxContainer4.visible = true
	EndActionPerformPhase()

func TrySetFire() -> bool:
	randomize()
	var random_value = randf()
	return random_value < 0.5

func ShipDestroyed(Ship : BattleShipStats) -> bool:
	RemoveShip(Ship)
	if (EnemyShips.size() == 0):
		await OnFightEnded(true)
		CardFightEnded.emit(PlayerShips)
		queue_free()
		return true
	if (PlayerShips.size() == 0):
		await OnFightEnded(false)
		CardFightEnded.emit(EnemyShips)
		queue_free()
		return true
	return false

func OnFightEnded(Won : bool) -> void:
	var EndScene = EndScene.instantiate() as CardFightEndScene
	EndScene.SetData(Won, FundsToWin, DamageDone, DamageGot, DamageNeg)
	add_child(EndScene)
	await EndScene.ContinuePressed
	return 
	
func ShowEndCard() -> void:
	pass

func EndActionPerformPhase() -> void:
	Actions.clear()
	StartActionPickPhase()

func NextShipActionPick() -> void:
	var CurrentShip = ShipTurns[CurrentTurn]
	Actions[CurrentShip] = []
	if (PlayerShips.has(CurrentShip)):
		RestartCards()
	else:
		EnemyActionSelection()

func PlayerActionSelectionEnded() -> void:
	ShipsViz[CurrentTurn].Dissable()
	if (CurrentTurn == ShipTurns.size() - 1):
		EndActionPickPhase()
		return
	CurrentTurn += 1
	NextShipActionPick()

func EnemyActionSelection() -> void:
	var CurrentShip = ShipTurns[CurrentTurn]
	var EnemyEnergy = 4
	
	if (GetShipViz(CurrentShip).IsOnFire()):
		var ExtinguishAction
		for g in Cards:
			if (g.CardName == "Extinguish fires"):
				ExtinguishAction = g
		EnemyEnergy -= ExtinguishAction.Energy
		Actions[CurrentShip].append(ExtinguishAction)
	
	while (EnemyEnergy > 0):
		var Action = (Cards.pick_random() as CardStats).duplicate()
		if (!Action.AllowDuplicates and Actions[CurrentShip].has(Action)):
			continue
		if (Action.CardName == "Extinguish fires"):
			continue
		EnemyEnergy -= Action.Energy
		if (EnemyEnergy > 0 and Action.Options.size() > 0):
			Action.SelectedOption = Action.Options.pick_random()
			EnemyEnergy -= Action.SelectedOption.EnergyAdd
		Actions[CurrentShip].append(Action)
	
	if (CurrentTurn == ShipTurns.size() - 1):
		EndActionPickPhase()
		return
	CurrentTurn += 1
	NextShipActionPick()

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
			offensive_card_plecements.add_child(c)
		else :
			deffensive_card_plecements.add_child(c)
	ShipsViz[CurrentTurn].Enable()

func UpdateHandCards() -> void:
	for g in offensive_card_plecements.get_children():
		g.queue_free()
	for g in deffensive_card_plecements.get_children():
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
			offensive_card_plecements.add_child(c)
		else :
			deffensive_card_plecements.add_child(c)

func ClearCards() -> void:
	for g in offensive_card_plecements.get_children():
		g.queue_free()
	for g in deffensive_card_plecements.get_children():
		g.queue_free()
	for g in selected_card_plecements.get_children():
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
	selected_card_plecements.add_child(c)
	Actions[CurrentShip].append(Action)
	
	if (C.CStats.Consume):
		var Cards = ShipTurns[CurrentTurn].Cards
		Cards[C.CStats] -= 1
		if (Cards[C.CStats] == 0):
			Cards.erase(C.CStats)
	if (Option != null):
		if (Option.CauseConsumption):
			var Ammo = ShipTurns[CurrentTurn].Ammo
			Ammo[Option] -= 1
			if (Ammo[Option] == 0):
				Ammo.erase(Option)
	UpdateEnergy()
	UpdateHandCards()

func RemoveCard(C : Card, Option : CardOption) -> void:
	C.queue_free()
	if (C.CStats.Consume):
		var Cards = ShipTurns[CurrentTurn].Cards
		if (!Cards.has(C.CStats)):
			Cards[C.CStats] = 1
		else:
			Cards[C.CStats] += 1
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
	$VBoxContainer4/VBoxContainer4/ProgressBar.value = Energy
	$VBoxContainer4/VBoxContainer4/ProgressBar/Label.text = var_to_str(Energy) + " / 4"

#func PlayOffensiveAction(SourcePos : Vector2, TargetPos : Vector2, Countered : bool) -> void:
	#pass

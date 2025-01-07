extends PanelContainer

class_name Card_Fight

@export var CardScene : PackedScene
@export var ShipVizScene : PackedScene
@export var Cards : Array[CardStats]
@export var ActionAnim : PackedScene

@onready var offensive_card_plecements: HBoxContainer = $VBoxContainer4/VBoxContainer4/VBoxContainer3/OffensiveCardPlecements
@onready var deffensive_card_plecements: HBoxContainer = $VBoxContainer4/VBoxContainer4/VBoxContainer3/DeffensiveCardPlecements
@onready var selected_card_plecements: HBoxContainer = $VBoxContainer4/VBoxContainer4/HBoxContainer2/SelectedCardPlecements

var Energy : int = 4

var ShipTurns : Array[BattleShipStats]

var CurrentTurn : int = 0

var PlayerShips : Array[BattleShipStats]
var EnemyShips : Array[BattleShipStats]

var ShipsViz : Array[CardFightShipViz]

var Actions : Dictionary

signal CardFightEnded(Survivors : Array[BattleShipStats])

func _ready() -> void:
	#for g in 3:
		#PlayerShips.append(GenerateRandomisedShip("Player" + var_to_str(g), false))
	#for g in 3:
		#EnemyShips.append(GenerateRandomisedShip("Enemy" + var_to_str(g), true))
	
	ShipTurns.append_array(PlayerShips)
	ShipTurns.append_array(EnemyShips)
	ShipTurns.sort_custom(speed_comparator)
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
	
func UpdateShipStats(BattleS : BattleShipStats) -> void:
	var Friendly : bool = PlayerShips.has(BattleS)
	var index = ShipTurns.find(BattleS)
	ShipsViz[index].SetStats(BattleS, Friendly)

func RemoveShip(Ship : BattleShipStats) -> void:
	var index = ShipTurns.find(Ship)
	ShipsViz[index].queue_free()
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
		for z in Actions[Ship]:
			var Action = z as CardStats
			if (Action is OffensiveCardStats):
				var friendly = PlayerShips.has(Ship)
				var Target
				if (friendly):
					Target = EnemyShips.pick_random()
				else :
					Target = PlayerShips.pick_random()
				
				var HasDeff = Actions[Target].has(Action.CounteredBy)
				
				var anim = ActionAnim.instantiate() as CardOffensiveAnimation
				anim.OriginIcon = Ship.ShipIcon
				anim.OriginShip = Ship
				anim.TargetIcon = Target.ShipIcon
				anim.AtackCard = Action
				
				if (HasDeff):
					Actions[Target].erase(Action.CounteredBy)
					print(Ship.Name + " has atacked " + Target.Name + " using " + Action.CardName + " but was countered")
					anim.DefCard = Action.CounteredBy
				else:
					Target.Hull -= Action.Damage * Ship.FirePower
					if (Target.Hull <= 0):
						if (ShipDestroyed(Target)):
							return
					else:
						UpdateShipStats(Target)
					
					print(Ship.Name + " has atacked " + Target.Name + " using " + Action.CardName)
				
				$VBoxContainer4.add_child(anim)
				$VBoxContainer4.move_child(anim, 1)
				await(anim.AnimationFinished)
	$VBoxContainer4/VBoxContainer4.visible = true
	EndActionPerformPhase()

func ShipDestroyed(Ship : BattleShipStats) -> bool:
	RemoveShip(Ship)
	if (EnemyShips.size() == 0):
		CardFightEnded.emit(PlayerShips)
		queue_free()
		return true
	if (PlayerShips.size() == 0):
		CardFightEnded.emit(EnemyShips)
		queue_free()
		return true
	return false
func EndActionPerformPhase() -> void:
	Actions.clear()
	StartActionPickPhase()

func NextShipActionPick() -> void:
	var CurrentShip = ShipTurns[CurrentTurn]
	Actions[CurrentShip] = []
	if (PlayerShips.has(CurrentShip)):
		UpdateCards()
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
	
	while (EnemyEnergy > 0):
		var Action = Cards.pick_random() as CardStats
		if (!Action.AllowDuplicates and Actions[CurrentShip].has(Action)):
			continue
		EnemyEnergy -= Action.Energy
		Actions[CurrentShip].append(Action)
	
	if (CurrentTurn == ShipTurns.size() - 1):
		EndActionPickPhase()
		return
	CurrentTurn += 1
	NextShipActionPick()

func UpdateCards() -> void:
	ClearCards()
	Energy = 4
	UpdateEnergy()
	for g in Cards:
		var c = CardScene.instantiate() as Card
		c.SetCardStats(g)
		c.connect("OnCardPressed", OnCardSelected)
		if (g is OffensiveCardStats):
			offensive_card_plecements.add_child(c)
		else :
			deffensive_card_plecements.add_child(c)
	ShipsViz[CurrentTurn].Enable()

func ClearCards() -> void:
	for g in offensive_card_plecements.get_children():
		g.queue_free()
	for g in deffensive_card_plecements.get_children():
		g.queue_free()
	for g in selected_card_plecements.get_children():
		g.queue_free()

func OnCardSelected(C : Card, Option : String) -> void:
	if (Energy < C.Cost):
		return
	
	var Action = C.CStats
	var CurrentShip = ShipTurns[CurrentTurn]
	if (!Action.AllowDuplicates and Actions[CurrentShip].has(Action)):
		return
	Energy -= C.Cost
	UpdateEnergy()
	var c = CardScene.instantiate() as Card
	c.SetCardStats(C.CStats, Option)
	c.connect("OnCardPressed", RemoveCard)
	selected_card_plecements.add_child(c)
	Actions[CurrentShip].append(Action)

func RemoveCard(C : Card, _Options : String) -> void:
	C.queue_free()
	var CurrentShip = ShipTurns[CurrentTurn]
	Actions[CurrentShip].erase(C.CStats)
	Energy += C.Cost
	UpdateEnergy()

func UpdateEnergy() -> void:
	$VBoxContainer4/VBoxContainer4/ProgressBar.value = Energy
	$VBoxContainer4/VBoxContainer4/ProgressBar/Label.text = var_to_str(Energy) + " / 4"

#func PlayOffensiveAction(SourcePos : Vector2, TargetPos : Vector2, Countered : bool) -> void:
	#pass

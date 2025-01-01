extends PanelContainer

class_name Card_Fight

@export var CardScene : PackedScene
@export var ShipVizScene : PackedScene
@export var Cards : Array[CardStats]

@onready var offensive_card_plecements: HBoxContainer = $VBoxContainer4/VBoxContainer4/VBoxContainer3/Offensive/OffensiveCardPlecements
@onready var deffensive_card_plecements: HBoxContainer = $VBoxContainer4/VBoxContainer4/VBoxContainer3/Deffensive/DeffensiveCardPlecements
@onready var selected_card_plecements: HBoxContainer = $VBoxContainer4/VBoxContainer4/HBoxContainer2/SelectedCardPlecements

var Energy : int = 4

var ShipTurns : Array[BattleShipStats]

var CurrentTurn : int = 0

var PlayerShips : Array[BattleShipStats]
var EnemyShips : Array[BattleShipStats]

func _ready() -> void:
	for g in 3:
		PlayerShips.append(GenerateRandomisedShip())
	for g in 3:
		EnemyShips.append(GenerateRandomisedShip())
	for g in PlayerShips:
		AddShip(g, true)
	for g in EnemyShips:
		AddShip(g, false)
	ShipTurns.append_array(PlayerShips)
	ShipTurns.append_array(EnemyShips)
	ShipTurns.sort_custom(speed_comparator)
	print("init done")
	UpdateCards(ShipTurns[0])
#function to sort battle ships based on their speed
static func speed_comparator(a, b):
	if a.Speed > b.Speed:
		return true  # -1 means 'a' should appear before 'b'
	elif a.Speed< b.Speed:
		return false  # 1 means 'b' should appear before 'a'
	return true
	
func AddShip(BattleS : BattleShipStats, Friendly : bool) -> void:
	var t = ShipVizScene.instantiate() as CardFightShipViz
	t.SetStats(BattleS, Friendly)
	if (Friendly):
		$VBoxContainer4/VBoxContainer.add_child(t)
	else :
		$VBoxContainer4/VBoxContainer2.add_child(t)
		

func GenerateRandomisedShip() -> BattleShipStats:
	var Stats = BattleShipStats.new()
	Stats.Name = "Test" + var_to_str(randi_range(1, 10))
	Stats.FirePower = randf_range(0.5, 3)
	Stats.Hull = randf_range(10, 800)
	Stats.Speed = randf_range(0.5, 3)
	Stats.ShipIcon = load("res://Assets/Spaceship/Spaceship_top_2_Main Camera.png")
	return Stats

func UpdateCards(Ship : BattleShipStats) -> void:
	for g in offensive_card_plecements.get_children():
		g.queue_free()
	for g in deffensive_card_plecements.get_children():
		g.queue_free()
	Energy = 4
	UpdateEnergy()
	for g in Cards:
		var c = CardScene.instantiate() as Card
		c.SetCardStats(g)
		c.connect("OnCardPressed", OnCardSelected)
		if (g.Offensive):
			offensive_card_plecements.add_child(c)
		else :
			deffensive_card_plecements.add_child(c)

func OnCardSelected(C : Card) -> void:
	if (Energy < C.Cost):
		return
	Energy -= C.Cost
	UpdateEnergy()
	var c = CardScene.instantiate() as Card
	c.SetCardStats(C.CStats)
	c.connect("OnCardPressed", RemoveCard)
	selected_card_plecements.add_child(c)

func RemoveCard(C : Card) -> void:
	C.queue_free()
	Energy += C.Cost
	UpdateEnergy()

func UpdateEnergy() -> void:
	$VBoxContainer4/VBoxContainer4/ProgressBar.value = Energy
	$VBoxContainer4/VBoxContainer4/ProgressBar/Label.text = var_to_str(Energy) + " / 4"

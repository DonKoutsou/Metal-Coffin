extends Node

class_name Card_Fight

@export var CardScene : PackedScene

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
		AddShipIcon(g.ShipIcon, true)
	for g in EnemyShips:
		AddShipIcon(g.ShipIcon, false)
	ShipTurns.append_array(PlayerShips)
	ShipTurns.append_array(EnemyShips)
	ShipTurns.sort_custom(speed_comparator)
	print("init done")

#function to sort battle ships based on their speed
static func speed_comparator(a, b):
	if a.Speed > b.Speed:
		return true  # -1 means 'a' should appear before 'b'
	elif a.Speed< b.Speed:
		return false  # 1 means 'b' should appear before 'a'
	return true
	
func AddShipIcon(Ic : Texture, Friendly : bool) -> void:
	var t = TextureRect.new()
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	t.texture = Ic
	if (Friendly):
		$VBoxContainer4/VBoxContainer.add_child(t)
	else :
		$VBoxContainer4/VBoxContainer2.add_child(t)
		t.flip_v = true

func GenerateRandomisedShip() -> BattleShipStats:
	var Stats = BattleShipStats.new()
	Stats.Name = "Test" + var_to_str(randi_range(1, 10))
	Stats.FirePower = randf_range(0.5, 3)
	Stats.Hull = randf_range(10, 800)
	Stats.Speed = randf_range(0.5, 3)
	Stats.ShipIcon = load("res://Assets/Spaceship/Spaceship_top_2_Main Camera.png")
	return Stats

func UpdateCards(Ship : BattleShipStats) -> void:
	#missile
	var card = CardScene.instantiate() as Card
	var CStats = CardStats.new()
	CStats.CardName = "Missile"
	CStats.Energy = 1
	CStats.Icon = load("res://Assets/Items/rocket.png")
	card.SetCardStats(CStats)
	

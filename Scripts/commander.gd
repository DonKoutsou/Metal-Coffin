extends Node

class_name Commander

static var Instance : Commander

var Fleet : Array[HostileShip] = []

var EnemyPositionsToInvestigate : Dictionary
var KnownEnemies : Array[MapShip] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Instance = self

static func GetInstance() -> Commander:
	return Instance

func RegisterSelf(Ship : HostileShip) -> void:
	Fleet.append(Ship)
	Ship.connect("OnShipDestroyed", OnShipDestroyed)
	
func OnShipDestroyed(Ship : HostileShip) -> void:
	Fleet.erase(Ship)

func OnEnemySeen(Ship : MapShip) -> void:
	KnownEnemies.append(Ship)
	
func OnEnemyVisualLost(Ship : MapShip) -> void:
	KnownEnemies.erase(Ship)
	EnemyPositionsToInvestigate[Ship] = Ship.global_position
	
func OnPositionInvestigated(Pos : Vector2) -> void:
	for g in EnemyPositionsToInvestigate.size():
		if (EnemyPositionsToInvestigate.values()[g] == Pos):
			EnemyPositionsToInvestigate.erase(EnemyPositionsToInvestigate.keys()[g])
			break

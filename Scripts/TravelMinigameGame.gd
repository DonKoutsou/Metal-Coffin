extends Node3D
class_name  TravelMinigameGame

@export var EnemyShapes : Array[Mesh]
@export var Enemy : PackedScene
@export var SuuplyScene : PackedScene

@export var EnemyGoal : int
@export var EnemySpawnRate : float
@onready var planet_pivot: Node3D = $PlanetPivot

signal OnGameEnded(Renault : bool)

var Supplies : Array[Item]
var enemies = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var fintrans = -50;
	var SuppliesList = [0, 0, 0, 0]
	for g in 4:
		SuppliesList[g] = randi_range(0, EnemyGoal)
	for g in EnemyGoal :
		if (SuppliesList.has(g)):
			var sup = SuuplyScene.instantiate()
			add_child(sup)
			var rand = RandomNumberGenerator.new()
			fintrans += -10
			sup.position.z = fintrans
			sup.position.x = rand.randf_range(-5, 5)
			sup.position.y = rand.randf_range(-3, 3)

		var enemy = Enemy.instantiate()
		add_child(enemy)
		enemy.SetMesh(EnemyShapes.pick_random())
		var ran = RandomNumberGenerator.new()
		fintrans += -10
		enemy.position.z = fintrans
		enemy.position.x = ran.randf_range(-5, 5)
		enemy.position.y = ran.randf_range(-3, 3)
	planet_pivot.position.z = fintrans -10

func SetDestinationMesh(Model : Mesh) -> void:
	$PlanetPivot/MeshInstance3D7.mesh = Model

func GameFinished(fin : bool) -> void:
	OnGameEnded.emit(fin, Supplies)
	queue_free()
	
func EnemyKilled() -> void:
	enemies += 1
	if (enemies >= EnemyGoal):
		GameFinished(true)
		
func SupplyGathered(supplycontents : Array[Item]) -> void:
	for g in supplycontents.size() :
		Supplies.insert(g, supplycontents[g])

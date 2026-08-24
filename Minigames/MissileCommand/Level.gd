
extends Control
class_name Level

signal LevelFinished

@export var FastDropMissileScene : PackedScene
@export var DropMissileScene : PackedScene
@export var Planes : PackedScene
@export var ScoreLabel : Label
@export var EndText : Label
@export var SpawnTimer : Timer

var Arsenal : Array[Enemy]
var SpawnedEnemies : Array[Enemy]
var Targets : Array[Desctructable]

var Score : int = 0

func SetDificulty(LevelNumber : int) -> void:
	var missileammount = 5 + LevelNumber * 3
	for g in missileammount :
		Arsenal.append(DropMissileScene.instantiate())
	for g in missileammount / 10.0:
		Arsenal.append(FastDropMissileScene.instantiate())
	for g in missileammount / 10.0:
		Arsenal.append(Planes.instantiate())
	SpawnTimer.wait_time = max(0.2, 2.0 - LevelNumber * 0.15)

func _ready() -> void:
	EndText.visible = false
	for g in get_tree().get_nodes_in_group("Destructable"):
		if (g is Desctructable):
			Targets.append(g)
			g.Destroyed.connect(TargetDestroyed.bind(g))

func TargetDestroyed(B : Desctructable) -> void:
	Targets.erase(B)
	if (Targets.size() == 0):
		GameFinished(false)

func GameFinished(Win : bool) -> void:
	get_tree().create_timer(2).timeout.connect(KillGame)
	EndText.visible = true
	ScoreLabel.visible = false
	var t : String
	if (Win):
		t = "Victory"
	else:
		t = "DEFEAT"
	EndText.text = "{0}\nSCORE : {1}".format([t, Score])

func KillGame() -> void:
	LevelFinished.emit()

func _on_spawn_timer_timeout() -> void:
	if (Targets.size() == 0 or Arsenal.size() == 0):
		return
	
	var NewEnemy = Arsenal.pop_at(randi_range(0, Arsenal.size() - 1)) as Enemy
	SpawnedEnemies.append(NewEnemy)
	
	
	NewEnemy.EnemyKilled.connect(OnEnemyDestroyed)
	#NewEnemy.Exploded.connect(OnMissileExploded.bind(NewMissile))
	
	add_child(NewEnemy)
	NewEnemy.Init(Targets)

func OnEnemyDestroyed(E : Enemy, ByPlayer : bool) -> void:
	SpawnedEnemies.erase(E)
	
	if (ByPlayer):
		Score += E.Points
		ScoreLabel.text = "Score : {0}".format([Score])
	
	if (Arsenal.size() == 0 and SpawnedEnemies.size() == 0):
		GameFinished(true)

extends Control

class_name EndlessLevel

signal LevelFinished

@export var FastDropMissileScene : PackedScene
@export var DropMissileScene : PackedScene
@export var Planes : PackedScene
@export var ScoreLabel : Label
@export var FinalScoreLabel : Label
@export var EndText : Label
@export var SpawnTimer : Timer

var Targets : Array[Desctructable]

var Score : int = 0

var TimePassesd : float

func _physics_process(delta: float) -> void:
	TimePassesd += delta

func _ready() -> void:
	for g in get_tree().get_nodes_in_group("Destructable"):
		if (g is Desctructable):
			Targets.append(g)
			g.Destroyed.connect(TargetDestroyed.bind(g))

func TargetDestroyed(B : Desctructable) -> void:
	Targets.erase(B)
	if (Targets.size() == 0):
		FinalScoreLabel.visible = true
		FinalScoreLabel.text = "Final Score " + var_to_str(Score)
		SpawnTimer.stop()

func _on_spawn_timer_timeout() -> void:
	if (Targets.size() == 0):
		return
	
	SpawnTimer.wait_time -= 0.002
	
	var r = randi_range(0, 1)
	var NewEnemy : Enemy
	
	if (r == 0):
		NewEnemy = DropMissileScene.instantiate()
	else : if (r == 1):
		NewEnemy = FastDropMissileScene.instantiate()
	else:
		NewEnemy = Planes.instantiate()
	
	NewEnemy.EnemyKilled.connect(OnEnemyDestroyed)

	add_child(NewEnemy)
	NewEnemy.Init(Targets)

func OnEnemyDestroyed(E : Enemy, ByPlayer : bool) -> void:
	if (ByPlayer):
		Score += E.Points
		ScoreLabel.text = "Score : {0}".format([Score])


func _on_button_pressed() -> void:
	LevelFinished.emit()

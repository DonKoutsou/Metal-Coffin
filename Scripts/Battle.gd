extends Control
class_name Battle

@export var DamageFloaterScene : PackedScene
@export var DamageFloaterPLScene : PackedScene

@onready var EnHp = $VBoxContainer2/EnemyHp as ProgressBar
@onready var PlHp = $VBoxContainer/PlayerHP as ProgressBar
@onready var AtTimer = $AtackTimer as Timer
@onready var ToffTimee = $TurnOffTimer as Timer
@onready var enemy_attack_timer: Timer = $EnemyAttackTimer

signal OnBattleEnded(Resault : bool, RemainingHP : int, Supplies : int)

var EnemyHp = 100
var PlayerHp = 100

var Attacking = false
var EnemyDead = false
var PlayerDead = false
var BattleResault = false
var Defending = false

var SupplyReward : Array[Item]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EnHp.max_value = 100
	EnHp.value = EnemyHp
	PlHp.max_value = 100
	PlHp.value = PlayerHp
	enemy_attack_timer.wait_time = randf_range(0.5, 3)

func _on_atack_pressed() -> void:
	if (Attacking or PlayerDead):
		return
	Attacking = true
	EnemyHp -= 10
	EnHp.value = EnemyHp
	if (EnemyHp <= 0):
		ToffTimee.start()
		EnemyDead = true
		BattleResault = true
	else :
		AtTimer.start()
	SpawnFloater(10)


func _on_atack_timer_timeout() -> void:
	Attacking = false

func _on_turn_off_timer_timeout() -> void:
	OnBattleEnded.emit(BattleResault, PlayerHp, SupplyReward)
	queue_free()
	
func SpawnFloater(Num : int) -> void:
	var floater = DamageFloaterScene.instantiate() as Label
	floater.text = var_to_str(Num)
	add_child(floater)

func SpawnPlayerFloater(Num : int) -> void:
	var floater = DamageFloaterPLScene.instantiate() as Label
	floater.text = var_to_str(Num)
	add_child(floater)
	floater.position.y +=  200

func _on_enemy_attack_timer_timeout() -> void:
	if (EnemyDead or PlayerDead):
		return
	enemy_attack_timer.wait_time = randf_range(0.5, 3)
	var damage = 10
	if (Defending):
		damage = 0
	PlayerHp -= damage
	PlHp.value = PlayerHp
	SpawnPlayerFloater(damage)
	var anim = $SubViewportContainer/SubViewport/MeshInstance3D/AnimationPlayer as AnimationPlayer
	anim.play("Anim")
	if (PlayerHp <= 0):
		PlayerDead = true
		ToffTimee.start()
		BattleResault = false


func _on_def_button_down() -> void:
	Defending = true

func _on_def_button_up() -> void:
	Defending = false

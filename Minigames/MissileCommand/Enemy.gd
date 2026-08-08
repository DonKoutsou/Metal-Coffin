extends Node2D

class_name Enemy

@export var Points : int = 100

signal EnemyKilled(ByPlayer : bool)

var Target : Desctructable
var TargetPosition : Vector2

func Init(PossibleTargets : Array[Desctructable]) -> void:
	Target = PossibleTargets.pick_random()
	TargetPosition = Target.global_position

func Kill() -> void:
	EnemyKilled.emit(self, true)
	queue_free()

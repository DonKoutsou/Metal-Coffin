@tool
extends Node2D

class_name TailBone2D

@export var influence : float = 1

var lastPosition : Vector2
var lastRotation : float

var lastRot : float
var lastForce : float

func _process(delta: float) -> void:
	var par : Node2D = get_parent()
	var newPos = par.global_position
	var parentRot = par.global_rotation
	
	var magnitude : float = (lastPosition - newPos).length()
	var dir = lastPosition.direction_to(newPos).rotated(-par.global_rotation)
	var force = -dir.x * magnitude * delta
	lastForce = clamp(force + lastForce, - 1, 1)
	
	var newRot = clamp(lastRot + ((lastRotation - parentRot) * influence) + (lastForce * influence), -PI / 5, PI / 5)

	rotation = newRot
	lastForce = lerp_angle(lastForce, 0.0, delta * 50)
	
	lastRot = lerp_angle(newRot, 0.0, delta)
	lastPosition = newPos
	lastRotation = parentRot

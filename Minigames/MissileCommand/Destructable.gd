extends Control

class_name Desctructable

signal Destroyed

var dead : bool = false

func Kill() -> void:
	Destroyed.emit()
	for g in get_children():
		if (g is Sprite2D):
			g.hide()
		if (g is Label):
			g.hide()
		if (g is Area2D):
			g.set_deferred("monitoring", false)
			g.set_deferred("monitorable", false)
	dead = true

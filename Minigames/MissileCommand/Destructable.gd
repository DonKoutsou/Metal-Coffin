extends Control

class_name Desctructable

signal Destroyed

func Kill() -> void:
	Destroyed.emit()
	queue_free()

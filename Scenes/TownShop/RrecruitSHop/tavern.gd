extends Control

class_name Tavern

signal RecShop
signal Arcade

func _on_button_pressed() -> void:
	RecShop.emit()
	queue_free()

func _on_button_2_pressed() -> void:
	Arcade.emit()
	queue_free()

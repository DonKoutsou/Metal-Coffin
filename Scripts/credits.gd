extends Control

signal OnButtonPressed

func _on_button_pressed() -> void:
	OnButtonPressed.emit()

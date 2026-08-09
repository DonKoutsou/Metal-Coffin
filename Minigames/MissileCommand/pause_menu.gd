extends CanvasLayer

class_name MC_PauseMenu

signal ContinuePressed
signal ExitToMenuPressed
signal ExitPressed


func _on_continue_pressed() -> void:
	ContinuePressed.emit()


func _on_exit_to_menu_pressed() -> void:
	ExitToMenuPressed.emit()


func _on_exit_pressed() -> void:
	ExitToMenuPressed.emit()

extends CanvasLayer

class_name StartingMenu

signal GameStart()

func _on_play_pressed() -> void:
	GameStart.emit()

func _on_exit_pressed() -> void:
	get_tree().quit()

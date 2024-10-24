extends CanvasLayer

class_name StartingMenu

signal GameStart(Load : bool)

func _on_play_pressed() -> void:
	GameStart.emit(false)

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_load_pressed() -> void:
	GameStart.emit(true)

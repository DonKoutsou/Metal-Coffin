extends Control

class_name MainMenu

signal LevelStarted(LevelNumber : int)

@export var LevelAmmount : int = 10

signal ExitPressed

func _ready() -> void:
	$VBoxContainer/GridContainer.columns = LevelAmmount / 2.0
	for g in range(1, LevelAmmount + 1):
		var b = Button.new()
		b.text = var_to_str(g)
		$VBoxContainer/GridContainer.add_child(b)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		b.pressed.connect(OnLevelSelected.bind(g))

func OnLevelSelected(LevelNumber : int) -> void:
	LevelStarted.emit(LevelNumber)

func _on_start_pressed() -> void:
	LevelStarted.emit(-1)


func _on_exit_pressed() -> void:
	ExitPressed.emit()

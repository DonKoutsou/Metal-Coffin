extends PanelContainer

class_name ItemTransfer
@export var ButtonPlecements : VBoxContainer

signal CharacterSelected()

var SelectedCharacter : Captain

func SetData(Characters : Array[Captain]) -> void:
	for g in Characters:
		var B = Button.new()
		B.text = g.CaptainName
		ButtonPlecements.add_child(B)
		B.connect("pressed", OnCharacterSelected.bind(g))
		
func OnCharacterSelected(Ch : Captain) -> void:
	SelectedCharacter = Ch
	CharacterSelected.emit()
	queue_free()

func _on_gui_input(event: InputEvent) -> void:
	if (event.is_action_pressed("Click")):
		CharacterSelected.emit()
		queue_free()

extends PanelContainer

class_name ItemTransfer
@export var CaptainButton : PackedScene
@export var ButtonPlecements : VBoxContainer

signal CharacterSelected()

var SelectedCharacter : Captain

func SetData(Characters : Array[Captain], HeaderText : String = "Transfer To") -> void:
	for g : Captain in Characters:
		var B = CaptainButton.instantiate() as FleetSeparationShipViz
		B.SetVisuals(g)
		ButtonPlecements.add_child(B)
		B.connect("OnShipSelected", OnCharacterSelected.bind(g))
	$VBoxContainer/Label.text = HeaderText
		
func OnCharacterSelected(Ch : Captain) -> void:
	SelectedCharacter = Ch
	CharacterSelected.emit()
	queue_free()

func _on_gui_input(event: InputEvent) -> void:
	if (event.is_action_pressed("Click")):
		CharacterSelected.emit()
		queue_free()

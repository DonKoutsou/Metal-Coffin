extends PanelContainer

class_name ItemTransfer
@export var CptnButton : PackedScene
@export var ButtonPlecements : VBoxContainer

signal CharacterSelected(TransferAmm : int)

var AmmountOwned : int = 0
var AmmountToTransfer : int = 1

var SelectedCharacter : Captain

func SetData(Characters : Array[Captain], HeaderText : String = "Transfer To") -> void:
	for g : Captain in Characters:
		var B = CptnButton.instantiate() as CaptainButton
		B.SetVisuals(g)
		ButtonPlecements.add_child(B)
		B.connect("OnShipSelected", OnCharacterSelected.bind(g))

	$VBoxContainer/PanelContainer/VBoxContainer/Label.text = HeaderText
	$"VBoxContainer/Transfer Text".visible = false
	$VBoxContainer/ItemName.visible = false
	$VBoxContainer/Panel.visible = false

func SetTransferData(Characters : Array[Captain], OwnedAmm : int, It : Item, HeaderText : String = "Transfer To") -> void:
	for g : Captain in Characters:
		var B = CptnButton.instantiate() as CaptainButton
		B.SetVisuals(g)
		ButtonPlecements.add_child(B)
		B.connect("OnShipSelected", OnCharacterSelected.bind(g))
	
	$VBoxContainer/ItemName.text = It.ItemName
	AmmountOwned = OwnedAmm
	$VBoxContainer/PanelContainer/VBoxContainer/Label.text = HeaderText
	$VBoxContainer/Panel/VBoxContainer/HBoxContainer/Label.text = var_to_str(AmmountToTransfer)
	$VBoxContainer/Panel.visible = OwnedAmm > 1
		
func OnCharacterSelected(Ch : Captain) -> void:
	SelectedCharacter = Ch
	CharacterSelected.emit(AmmountToTransfer)
	queue_free()

func _on_gui_input(event: InputEvent) -> void:
	if (event.is_action_pressed("Click")):
		CharacterSelected.emit(AmmountToTransfer)
		queue_free()



func _on_button_pressed() -> void:
	
	AmmountToTransfer = max(1, AmmountToTransfer - 1)
	$VBoxContainer/Panel/VBoxContainer/HBoxContainer/Label.text = var_to_str(AmmountToTransfer)


func _on_button_2_pressed() -> void:
	if (AmmountToTransfer == AmmountOwned):
		PopUpManager.GetInstance().DoFadeNotif("Max number reached")
	AmmountToTransfer = min(AmmountOwned, AmmountToTransfer + 1)
	$VBoxContainer/Panel/VBoxContainer/HBoxContainer/Label.text = var_to_str(AmmountToTransfer)

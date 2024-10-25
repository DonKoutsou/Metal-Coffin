extends PanelContainer

class_name ItemDescriptor

signal ItemUsed(It : Item)
signal ItemUpgraded(Part : ShipPart)
signal ItemDropped(It : Item)

var DescribedItem : Item
var OwnedAmm : int
var UsingAmm : int = 1
func SetData(It : Item, Amm : int) -> void:
	DescribedItem = It
	OwnedAmm = Amm
	$VBoxContainer/HBoxContainer/VBoxContainer2/TextureRect.texture = It.ItemIcon
	$VBoxContainer/HBoxContainer/VBoxContainer/ItemName.text = It.ItemName
	if (It is ShipPart):
		$VBoxContainer/HBoxContainer/VBoxContainer2/ItemDesc.text = It.ItemDesc + "\nProvides " + var_to_str(It.UpgradeAmm)+ " of "  + It.UpgradeName 
		$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer.visible = false
		if (It.UpgradeVersion == null):
			$VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer.visible = false
			$VBoxContainer/HBoxContainer/VBoxContainer2/UpgradeContainer.visible = false
		else:
			$VBoxContainer/HBoxContainer/VBoxContainer2/UpgradeContainer/TextureRect.texture = (It.UpgradeItems[0] as Item).ItemIconSmol
			$VBoxContainer/HBoxContainer/VBoxContainer2/UpgradeContainer/Label.text = "Upgrade Cost : " + var_to_str(It.UpgradeItems.size()) + "x"
	else :
		$VBoxContainer/HBoxContainer/VBoxContainer2/ItemDesc.text = It.ItemDesc
		$VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer.visible = false
		$VBoxContainer/HBoxContainer/VBoxContainer2/UpgradeContainer.visible = false
func _on_close_pressed() -> void:
	queue_free()
	
func _on_use_pressed() -> void:
	var dig = ConfirmationDialog.new()
	dig.connect("confirmed", ConfirmUse)
	add_child(dig)
	dig.dialog_text = "Are you sure you want to use this item ?"
	dig.ok_button_text = "Use"
	dig.popup_centered()

func _on_upgrade_pressed() -> void:
	var dig = ConfirmationDialog.new()
	dig.connect("confirmed", ConfirmUpgrade)
	add_child(dig)
	dig.dialog_text = "Are you sure you want to upgrade this item ?"
	dig.ok_button_text = "Upgrade"
	dig.popup_centered()

func _on_drop_pressed() -> void:
	var dig = ConfirmationDialog.new()
	dig.connect("confirmed", ConfirmDrop)
	add_child(dig)
	dig.dialog_text = "Are you sure you want to drop this item ?"
	dig.ok_button_text = "Drop"
	dig.popup_centered()
func ConfirmDrop() -> void:
	ItemDropped.emit(DescribedItem)
	queue_free()
func ConfirmUse() -> void:
	ItemUsed.emit(DescribedItem, UsingAmm)
func ConfirmUpgrade() -> void:
	ItemUpgraded.emit(DescribedItem)


func _on_use_more_pressed() -> void:
	UsingAmm = min(UsingAmm + 1, OwnedAmm)
	$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/Use.text = "Use :" + var_to_str(UsingAmm) + "x"

func _on_use_less_pressed() -> void:
	UsingAmm = max(UsingAmm - 1, 1)
	$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/Use.text = "Use :" + var_to_str(UsingAmm) + "x"

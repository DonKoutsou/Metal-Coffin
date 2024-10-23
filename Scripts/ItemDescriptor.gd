extends PanelContainer

class_name ItemDescriptor

signal ItemUsed(It : Item)
signal ItemUpgraded(Part : ShipPart)
signal ItemDropped(It : Item)

var DescribedItem : Item

func SetData(It : Item) -> void:
	DescribedItem = It
	$VBoxContainer/HBoxContainer/TextureRect.texture = It.ItemIcon
	$VBoxContainer/HBoxContainer/VBoxContainer/ItemName.text = It.ItemName
	if (It is ShipPart):
		$VBoxContainer/HBoxContainer/VBoxContainer/ItemDesc.text = It.ItemDesc + "\nProvides " + var_to_str(It.UpgradeAmm)+ " of "  + It.UpgradeName 
		$VBoxContainer/HBoxContainer/VBoxContainer/Use.visible = false
		if (It.UpgradeVersion == null):
			$VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer.visible = false
		else:
			$VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer/UpgradeContainer/TextureRect.texture = (It.UpgradeItems[0] as Item).ItemIconSmol
			$VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer/UpgradeContainer/Label.text = "Upgrade Cost : " + var_to_str(It.UpgradeItems.size()) + "x"
	else :
		$VBoxContainer/HBoxContainer/VBoxContainer/ItemDesc.text = It.ItemDesc
		$VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer.visible = false
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
	ItemUsed.emit(DescribedItem)
func ConfirmUpgrade() -> void:
	ItemUpgraded.emit(DescribedItem)

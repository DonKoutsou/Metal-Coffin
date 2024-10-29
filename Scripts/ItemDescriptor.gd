extends PanelContainer

class_name ItemDescriptor

signal ItemUsed(Cont : ItemContainer, Amm : int)
signal ItemUpgraded(Part : ShipPart)
signal ItemDropped(It : Item)

var DescribedContainer : ItemContainer
#var DescribedItem : Item
#var OwnedAmm : int
var UsingAmm : int = 1

func _ready() -> void:
	UISoundMan.GetInstance().Refresh()
func SetData(Cont : ItemContainer) -> void:
	DescribedContainer = Cont
	#DescribedItem = It
	#OwnedAmm = Amm
	$VBoxContainer/HBoxContainer/VBoxContainer2/TextureRect.texture = DescribedContainer.ItemType.ItemIcon
	if (DescribedContainer.ItemType is UsableItem):
		$VBoxContainer/HBoxContainer/VBoxContainer2/TextureRect.modulate = DescribedContainer.ItemType.ItecColor
	$VBoxContainer/HBoxContainer/VBoxContainer/ItemName.text = DescribedContainer.ItemType.ItemName
	if (DescribedContainer.ItemType is ShipPart):
		$VBoxContainer/HBoxContainer/VBoxContainer2/ItemDesc.text = DescribedContainer.ItemType.ItemDesc + "\nProvides " + var_to_str(DescribedContainer.ItemType.UpgradeAmm)+ " of "  + DescribedContainer.ItemType.UpgradeName 
		$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer.visible = false
		if (DescribedContainer.ItemType.UpgradeVersion == null):
			$VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer.visible = false
			$VBoxContainer/HBoxContainer/VBoxContainer2/UpgradeContainer.visible = false
		else:
			$VBoxContainer/HBoxContainer/VBoxContainer2/UpgradeContainer/TextureRect.texture = (DescribedContainer.ItemType.UpgradeItems[0] as Item).ItemIconSmol
			$VBoxContainer/HBoxContainer/VBoxContainer2/UpgradeContainer/Label.text = "Upgrade Cost : " + var_to_str(DescribedContainer.ItemType.UpgradeItems.size()) + "x"
	else :
		$VBoxContainer/HBoxContainer/VBoxContainer2/ItemDesc.text = DescribedContainer.ItemType.ItemDesc
		$VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer.visible = false
		$VBoxContainer/HBoxContainer/VBoxContainer2/UpgradeContainer.visible = false
func _on_close_pressed() -> void:
	queue_free()
	
func _on_use_pressed() -> void:
	PopUpManager.GetInstance().DoConfirm("Are you sure you want to use this item ?", "Use", ConfirmUse)

func _on_upgrade_pressed() -> void:
	PopUpManager.GetInstance().DoConfirm("Are you sure you want to upgrade this item ?", "Upgrade", ConfirmUpgrade)

func _on_drop_pressed() -> void:
	PopUpManager.GetInstance().DoConfirm("Are you sure you want to drop this item ?", "Drop", ConfirmDrop)
func ConfirmDrop() -> void:
	ItemDropped.emit(DescribedContainer.ItemType)
	queue_free()
func ConfirmUse() -> void:
	ItemUsed.emit(DescribedContainer, UsingAmm)
	UsingAmm = 1
	$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/Use.text = "Use :" + var_to_str(UsingAmm) + "x"
func ConfirmUpgrade() -> void:
	ItemUpgraded.emit(DescribedContainer.ItemType)


func _on_use_more_pressed() -> void:
	UsingAmm = min(UsingAmm + 1, DescribedContainer.Ammount)
	$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/Use.text = "Use :" + var_to_str(UsingAmm) + "x"
	
func _on_use_less_pressed() -> void:
	UsingAmm = max(UsingAmm - 1, 1)
	$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/Use.text = "Use :" + var_to_str(UsingAmm) + "x"

extends PanelContainer

class_name ItemDescriptor

signal ItemUsed(Cont : ItemContainer, Amm : int)
signal ItemUpgraded(Cont : ItemContainer)
signal ItemDropped(Cont : ItemContainer)
signal ItemRepaired(Cont : ItemContainer)

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
	$VBoxContainer/HBoxContainer/VBoxContainer/TextureRect.texture = DescribedContainer.ItemType.ItemIcon
	if (DescribedContainer.ItemType is UsableItem):
		$VBoxContainer/HBoxContainer/VBoxContainer/TextureRect.modulate = DescribedContainer.ItemType.ItecColor
	$VBoxContainer/HBoxContainer/VBoxContainer/ItemName.text = DescribedContainer.ItemType.ItemName
	#Ship Parts
	if (DescribedContainer.ItemType is ShipPart):
		
		$VBoxContainer/HBoxContainer/VBoxContainer2/ItemDesc.text = DescribedContainer.ItemType.ItemDesc + "\nProvides " + var_to_str(DescribedContainer.ItemType.UpgradeAmm)+ " of "  + DescribedContainer.ItemType.UpgradeName 
		$VBoxContainer/HBoxContainer/VBoxContainer/UsableItemsActions.visible = false
		#Damage
		$VBoxContainer/HBoxContainer/VBoxContainer/ShipPartActions/Repair.visible = DescribedContainer.ItemType.IsDamaged
		#Upgrade
		if (DescribedContainer.ItemType.UpgradeVersion == null):
			$VBoxContainer/HBoxContainer/VBoxContainer/ShipPartActions/Upgrade.visible = false
			$VBoxContainer/HBoxContainer/VBoxContainer/UpgradeContainer.visible = false
		else:
			$VBoxContainer/HBoxContainer/VBoxContainer/UpgradeContainer/TextureRect.texture = (DescribedContainer.ItemType.UpgradeItems[0] as Item).ItemIconSmol
			$VBoxContainer/HBoxContainer/VBoxContainer/UpgradeContainer/Label.text = "Upgrade Cost : " + var_to_str(DescribedContainer.ItemType.UpgradeItems.size()) + "x"
	else :
		$VBoxContainer/HBoxContainer/VBoxContainer2/ItemDesc.text = DescribedContainer.ItemType.ItemDesc
		$VBoxContainer/HBoxContainer/VBoxContainer/ShipPartActions.visible = false
		$VBoxContainer/HBoxContainer/VBoxContainer/UpgradeContainer.visible = false
func _on_close_pressed() -> void:
	queue_free()
func _on_use_pressed() -> void:
	PopUpManager.GetInstance().DoConfirm("Are you sure you want to use this item ?", "Use", ConfirmUse)

func _on_upgrade_pressed() -> void:
	PopUpManager.GetInstance().DoConfirm("Are you sure you want to upgrade this item ?", "Upgrade", ConfirmUpgrade)

func _on_drop_pressed() -> void:
	PopUpManager.GetInstance().DoConfirm("Are you sure you want to drop this item ?", "Drop", ConfirmDrop)
func ConfirmDrop() -> void:
	ItemDropped.emit(DescribedContainer)
	queue_free()
func ConfirmUse() -> void:
	ItemUsed.emit(DescribedContainer, UsingAmm)
	UsingAmm = 1
	$VBoxContainer/HBoxContainer/VBoxContainer/UsableItemsActions/Use.text = "Use :" + var_to_str(UsingAmm) + "x"
func ConfirmUpgrade() -> void:
	ItemUpgraded.emit(DescribedContainer)
func _on_use_more_pressed() -> void:
	UsingAmm = min(UsingAmm + 1, DescribedContainer.Ammount)
	$VBoxContainer/HBoxContainer/VBoxContainer/UsableItemsActions/Use.text = "Use :" + var_to_str(UsingAmm) + "x"
func _on_use_less_pressed() -> void:
	UsingAmm = max(UsingAmm - 1, 1)
	$VBoxContainer/HBoxContainer/VBoxContainer/UsableItemsActions/Use.text = "Use :" + var_to_str(UsingAmm) + "x"
func _on_repair_pressed() -> void:
	ItemRepaired.emit(DescribedContainer)

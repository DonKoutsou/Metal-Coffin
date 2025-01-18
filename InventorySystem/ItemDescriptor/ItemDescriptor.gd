extends PanelContainer

class_name ItemDescriptor

@export_group("UI Pieces")
#@export var ItemIcon : TextureRect
@export var ItemName : Label
@export var ItemDesc : RichTextLabel
@export var UsableItemsActions : HBoxContainer
#@export var UpgradeContainer : HBoxContainer
@export var ShipPartActions : HBoxContainer
@export var RepairButton : Button
@export var UseButton : Button
@export var TransferButton : Button
@export var UpgradeButton : Button
@export var UpgradeLabel : RichTextLabel

#signal ItemUsed(Box : Inventory_Box, Amm : int)
signal ItemUpgraded(Box : Inventory_Box)
signal ItemDropped(Box : Inventory_Box)
signal ItemRepaired(Box : Inventory_Box)
signal ItemTransf(Box : Inventory_Box)

var DescribedContainer : Inventory_Box
var UsingAmm : int = 1

#func _ready() -> void:
	#UISoundMan.GetInstance().Refresh()
	
func SetData(Box : Inventory_Box) -> void:
	set_physics_process(false)
	DescribedContainer = Box
	var It = DescribedContainer.GetContainedItem()
	#ItemIcon.texture = It.ItemIcon
	ItemDesc.text = It.GetItemDesc()
	
	#if (It is UsableItem):
		#UsableItemsActions.visible = true
		#ItemIcon.modulate = It.ItecColor
	#else :
	UsableItemsActions.visible = false
	
	
	ItemName.text = It.ItemName
	#Ship Parts
	if (It is ShipPart):
		TransferButton.visible = false
		UsableItemsActions.visible = false
		ShipPartActions.visible = true
		#RepairButton.visible = DescribedContainer.ItemType.IsDamaged
		UpgradeLabel.visible = true
		if (It.UpgradeVersion == null):
			UpgradeButton.visible = false
			UpgradeLabel.visible = false
		else:
			var inv = Box.GetParentInventory()
			if (inv.GetItemBeingUpgraded() == Box):
				set_physics_process(true)
				UpgradeButton.visible = false
			else:
				UpgradeButton.visible = true
				UpgradeLabel.text = "[color=#c19200]Upgrade Time[/color] : " + var_to_str(It.UpgradeTime)
	else :
		TransferButton.visible = true
		ShipPartActions.visible = false
		UpgradeLabel.visible = false
		
#func _on_use_pressed() -> void:
	#PopUpManager.GetInstance().DoConfirm("Are you sure you want to use this item ?", "Use", ConfirmUse)

func _on_upgrade_pressed() -> void:
	PopUpManager.GetInstance().DoConfirm("Are you sure you want to upgrade this item ?", "Upgrade", ConfirmUpgrade)


func _on_drop_pressed() -> void:
	PopUpManager.GetInstance().DoConfirm("Are you sure you want to drop this item ?", "Drop", ConfirmDrop)
	
	
func ConfirmDrop() -> void:
	ItemDropped.emit(DescribedContainer)
	queue_free()
	
	
#func ConfirmUse() -> void:
	#ItemUsed.emit(DescribedContainer, UsingAmm)
	#UsingAmm = 1
	#UseButton.text = "Use :" + var_to_str(UsingAmm) + "x"
	
	
func ConfirmUpgrade() -> void:
	ItemUpgraded.emit(DescribedContainer)
	queue_free()
	
func _on_use_more_pressed() -> void:
	UsingAmm = min(UsingAmm + 1, DescribedContainer.Ammount)
	UseButton.text = "Use :" + var_to_str(UsingAmm) + "x"
	
	
func _on_use_less_pressed() -> void:
	UsingAmm = max(UsingAmm - 1, 1)
	UseButton.text = "Use :" + var_to_str(UsingAmm) + "x"
	
	
func _on_repair_pressed() -> void:
	ItemRepaired.emit(DescribedContainer)

func _on_transfer_pressed() -> void:
	ItemTransf.emit(DescribedContainer)
	queue_free()

func _physics_process(_delta: float) -> void:
	var inv = DescribedContainer.GetParentInventory()
	var TimeLeft = var_to_str(roundi(inv.GetUpgradeTimeLeft()))
	UpgradeLabel.text = "Upgrade time left : {0} minutes".format([TimeLeft])

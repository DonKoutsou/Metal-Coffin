extends Control

class_name ItemDescriptor

@export_group("Scenes")
@export var CardScene : PackedScene
@export_group("UI Pieces")
#@export var ItemIcon : TextureRect
@export var ItemName : Label
@export var ItemDesc : RichTextLabel
@export var UsableItemsActions : HBoxContainer
@export var RepairButton : Button
@export var UseButton : Button
@export var TransferButton : Button
@export var UpgradeButton : Button
@export var UpgradeLabel : RichTextLabel
@export var CardSection : Control
@export var CardPlecement : Control
@export var DescScroll : ScrollContainer
@export var CardScroll : ScrollContainer
#signal ItemUsed(Box : Inventory_Box, Amm : int)
signal ItemUpgraded(Box : Inventory_Box)
signal ItemDropped(Box : Inventory_Box)
signal ItemRepaired(Box : Inventory_Box)
signal ItemTransf(Box : Inventory_Box)

var DescribedContainer : Inventory_Box
var UsingAmm : int = 1

func _ready() -> void:
	call_deferred("PlayIntroAnim")
	UISoundMan.GetInstance().AddSelf($VBoxContainer/HBoxContainer/HBoxContainer/ShipPartActions/Upgrade)
	UISoundMan.GetInstance().AddSelf($VBoxContainer/HBoxContainer/HBoxContainer/ShipPartActions/Transfer)
	
		

func DescriptorTutorial() -> void:
	pass

func PlayIntroAnim() -> void:
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "size", Vector2(size.x, size.y), 0.5)
	set_deferred("size", Vector2(size.x, 0))
	await tw.finished
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.ITEM_INSPECTION)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.ITEM_INSPECTION)
		var tuttext = "When selecting an [color=#c19200]Item[/color] you can check the items details that apear on the panel to the right. There you can choose to [color=#c19200]Upgrade[/color] it if its a ship part, [color=#c19200]Transfer[/color] it to another ship if its allowed and check any [color=#c19200]Cards[/color] it provides in close quarters combat."
		ActionTracker.GetInstance().ShowTutorial("Item Inspection", tuttext, [self], true)

func SetData(Box : Inventory_Box, CanUpgrade : bool) -> void:
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
	
	TransferButton.visible = It.CanTransfer
	
	ItemName.text = It.ItemName
	#Ship Parts
	if (It is ShipPart):
		UsableItemsActions.visible = false
		
		#ShipPartActions.visible = true
		#RepairButton.visible = DescribedContainer.ItemType.IsDamaged
		#if (CanUpgrade):
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
				var UpTime = It.UpgradeTime
				var UpCost = It.UpgradeCost
				if (CanUpgrade):
					UpTime /= 2
					UpCost /= 2
				UpgradeLabel.text = "[color=#c19200]Upgrade Time[/color] : {0}\n[color=#c19200]Upgrade Cost[/color] : {1}\n[color=#c19200]-------------".format([UpTime, UpCost])
		
	else :
		
		UpgradeButton.visible = false
		UpgradeLabel.visible = false
	
	if (It.CardProviding.size() > 0):
		for g in It.CardProviding:
			var CardS = g.duplicate() as CardStats
			var card = CardScene.instantiate() as Card
			
			if (It.CardOptionProviding != null):
				CardS.SelectedOption = It.CardOptionProviding
			card.SetCardStats(CardS, [])
			CardPlecement.add_child(card)
			card.Dissable()
	else:
		CardSection.visible = false
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
	#queue_free()
	
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
	#queue_free()

func _physics_process(_delta: float) -> void:
	var inv = DescribedContainer.GetParentInventory()
	var TimeLeft = var_to_str(roundi(inv.GetUpgradeTimeLeft()))
	UpgradeLabel.text = "Upgrade time left : {0} minutes".format([TimeLeft])


func CardScrolInput(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		CardScroll.scroll_horizontal -= event.relative.x

func OnDescScrollInput(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		DescScroll.scroll_vertical -= event.relative.y

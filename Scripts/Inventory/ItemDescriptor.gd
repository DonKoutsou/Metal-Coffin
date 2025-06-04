extends Control

class_name ItemDescriptor

@export var Workshop : bool = false
@export_group("Scenes")
@export var CardScene : PackedScene
@export_group("UI Pieces")
@export var ItemName : Label
@export var ItemDesc : RichTextLabel

@export var TransferButton : Button
@export var UpgradeButton : Button
@export var AddItemButton : Button
@export var IncreaseItemButton : Button
@export var RemoveItemButton : Button
@export var UpgradeLabel : RichTextLabel
@export var CardSection : Control
@export var CardPlecement : Control

signal ItemUpgraded(Box : Inventory_Box)
signal ItemDropped(Box : Inventory_Box)
signal ItemRepaired(Box : Inventory_Box)
signal ItemTransf(Box : Inventory_Box)
signal ItemRemove(Box : Inventory_Box)
signal ItemAdd(Box : Inventory_Box)
signal ItemIncrease(Box : Inventory_Box)

var DescribedContainer : Inventory_Box
var DescribedItem : Item
var UsingAmm : int = 1

func _ready() -> void:
	Helper.GetInstance().CallLater(PlayIntroAnim, 0.01)
	UISoundMan.GetInstance().AddSelf(TransferButton)
	UISoundMan.GetInstance().AddSelf(UpgradeButton)
	UISoundMan.GetInstance().AddSelf(AddItemButton)
	UISoundMan.GetInstance().AddSelf(IncreaseItemButton)
	UISoundMan.GetInstance().AddSelf(RemoveItemButton)
	

func DescriptorTutorial() -> void:
	pass

func PlayIntroAnim() -> void:
	#get_child(0).visible = false
	var tw = create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "size", size, 0.5)
	if (Workshop):
		get_child(0).get_child(0).visible = false
		size = Vector2(0, size.y)
	else:
		size = Vector2(size.x, 0)
		#set_deferred("size", Vector2(size.x, 0))
	await tw.finished
	get_child(0).get_child(0).visible = true
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.ITEM_INSPECTION)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.ITEM_INSPECTION)
		var tuttext = "When selecting an [color=#ffc315]Item[/color] you can check the items details that apear on the panel to the right. There you can choose to [color=#ffc315]Upgrade[/color] it if its a ship part, [color=#ffc315]Transfer[/color] it to another ship if its allowed and check any [color=#ffc315]Cards[/color] it provides in close quarters combat."
		ActionTracker.GetInstance().ShowTutorial("Item Inspection", tuttext, [self], true)

func SetWorkShopData(Box : Inventory_Box, CanUpgrade : bool, Owner : Captain) -> void:
	set_physics_process(false)
	DescribedContainer = Box
	var It = DescribedContainer.GetContainedItem()
	#ItemIcon.texture = It.ItemIcon
	#ItemDesc.text = It.GetItemDesc()
	
	#TransferButton.visible = It.CanTransfer
	TransferButton.visible = false
	AddItemButton.visible = false
	UpgradeButton.visible = true
	ItemName.text = It.ItemName
	#Ship Parts
	if (It is ShipPart):
		
		#ShipPartActions.visible = true
		#RepairButton.visible = DescribedContainer.ItemType.IsDamaged
		#if (CanUpgrade):
		UpgradeLabel.visible = true
		if (It.UpgradeVersion == null):
			UpgradeButton.visible = false
			UpgradeLabel.visible = false
		else:
			var inv = Owner.GetCharacterInventory()
			if (inv.GetItemBeingUpgraded() != null and inv.GetItemBeingUpgraded().GetContainedItem() == It):
				#set_physics_process(true)
				UpgradeButton.visible = false
				var TimeLeft = var_to_str(roundi(inv.GetUpgradeTimeLeft()))
				UpgradeLabel.text = "Upgrade time left : {0} minutes".format([TimeLeft])
			else:
				UpgradeButton.visible = true
				var UpTime = It.UpgradeTime
				var UpCost = It.UpgradeCost
				if (CanUpgrade):
					UpTime /= 2
					UpCost /= 2
				UpgradeLabel.text = "[color=#ffc315]Upgrade Time[/color] : {0}\n[color=#ffc315]Upgrade Cost[/color] : {1}".format([roundi(UpTime), roundi(UpCost)])
		
	else :
		
		UpgradeButton.visible = false
		UpgradeLabel.visible = false
	
	#TODO Option doesent show when ship has upgraded weapons
	if (It.CardProviding.size() > 0):
		var CardsChecked : Array[CardStats]
		for g in It.CardProviding:
			if (CardsChecked.has(g)):
				continue
			CardsChecked.append(g)
			
			var CardS = g.duplicate() as CardStats
			CardS.Tier = It.Tier
			var card = CardScene.instantiate() as Card
			
			#if (It.CardOptionProviding != null):
				#CardS.SelectedOption = It.CardOptionProviding
			card.SetCardStats(CardS, It.CardProviding.count(g))
			CardPlecement.add_child(card)
			card.Dissable()
	else:
		CardSection.visible = false

func SetMerchData(Itm : Item) -> void:
	for g in CardPlecement.get_children():
		g.queue_free()
		
	set_physics_process(false)
	DescribedItem = Itm
	#ItemIcon.texture = It.ItemIcon
	#ItemDesc.text = It.GetItemDesc()
	ItemDesc.text = Itm.GetItemDesc()
	#TransferButton.visible = It.CanTransfer
	TransferButton.visible = false
	
	ItemName.text = Itm.ItemName
	#Ship Parts
	if (Itm is ShipPart):
		
		#ShipPartActions.visible = true
		#RepairButton.visible = DescribedContainer.ItemType.IsDamaged
		#if (CanUpgrade):
		UpgradeLabel.visible = true
		if (Itm.UpgradeVersion == null):
			UpgradeButton.visible = false
			UpgradeLabel.visible = false
		else:

			UpgradeButton.visible = true
			var UpTime = Itm.UpgradeTime
			var UpCost = Itm.UpgradeCost
			UpgradeLabel.text = "[color=#ffc315]Upgrade Time[/color] : {0}\n[color=#ffc315]Upgrade Cost[/color] : {1}".format([roundi(UpTime), roundi(UpCost)])
	
	else :
		
		UpgradeButton.visible = false
		UpgradeLabel.visible = false
	
	#TODO Option doesent show when ship has upgraded weapons
	if (Itm.CardProviding.size() > 0):
		var CardsChecked : Array[CardStats]
		for g in Itm.CardProviding:
			if (CardsChecked.has(g)):
				continue
			CardsChecked.append(g)
			
			var CardS = g.duplicate() as CardStats
			CardS.Tier = Itm.Tier
			var card = CardScene.instantiate() as Card
			
			#if (It.CardOptionProviding != null):
				#CardS.SelectedOption = It.CardOptionProviding
			card.SetCardStats(CardS, Itm.CardProviding.count(g))
			CardPlecement.add_child(card)
			card.Dissable()
		CardSection.visible = true
	else:
		CardSection.visible = false

func SetData(Box : Inventory_Box, UpgradeBoost : bool, CanUpgrade : bool, CanTransfer : bool, CanAdd : bool, CanRemove : bool, ShowDescription : bool) -> void:
	set_physics_process(false)
	
	
	DescribedContainer = Box
	var It = DescribedContainer.GetContainedItem()
	
	ItemName.text = It.ItemName
	ItemDesc.text = It.GetItemDesc()
	ItemDesc.visible = ShowDescription
	
	TransferButton.visible = CanTransfer and !DescribedContainer.IsEmpty()
	UpgradeButton.visible = CanUpgrade
	AddItemButton.visible = CanAdd and DescribedContainer.IsEmpty()
	RemoveItemButton.visible = CanRemove
	#Ship Parts
	if (It is ShipPart):
		IncreaseItemButton.visible = false
		UpgradeLabel.visible = CanUpgrade
		if (It.UpgradeVersion == null):
			UpgradeButton.visible = false
			UpgradeLabel.visible = false
		else:
			var inv = Box.GetParentInventory()
			if (inv != null and inv.GetItemBeingUpgraded() == Box):
				set_physics_process(true)
				UpgradeButton.visible = CanUpgrade
			else:
				UpgradeButton.visible = CanUpgrade
				var UpTime = It.UpgradeTime
				var UpCost = It.UpgradeCost
				if (CanUpgrade):
					UpTime /= 2
					UpCost /= 2
				UpgradeLabel.text = "[color=#ffc315]Upgrade Time[/color] : {0}\n[color=#ffc315]Upgrade Cost[/color] : {1}\n[color=#ffc315]-------------".format([UpTime, UpCost])
	else :
		IncreaseItemButton.visible = CanAdd
		UpgradeButton.visible = false
		UpgradeLabel.visible = false
	
	for g in CardPlecement.get_children():
		g.queue_free()
		
	if (It.CardProviding.size() > 0):
		CardSection.get_parent().visible = true
		var CardsChecked : Array[CardStats]
		for g in It.CardProviding:
			if (CardsChecked.has(g)):
				continue
			
			CardsChecked.append(g)
			
			var CardS = g.duplicate() as CardStats
			CardS.Tier = It.Tier
			var card = CardScene.instantiate() as Card
			card.SetCardStats(CardS, It.CardProviding.count(g))
			CardPlecement.add_child(card)
			card.Dissable()
	else:
		CardSection.get_parent().visible = false

func SetEmptyShopData(Type : ShipPart.ShipPartType) -> void:
	UpgradeButton.visible = false
	AddItemButton.visible = true
	TransferButton.visible = false
	UpgradeLabel.visible = false
	if (ItemDesc != null):
		ItemDesc.visible = false
	set_physics_process(false) 
	ItemName.text = "Empty {0} Slot".format([ShipPart.ShipPartType.keys()[Type]])
	CardSection.get_parent().visible = false

func _on_upgrade_pressed() -> void:
	ItemUpgraded.emit(DescribedContainer)
	#PopUpManager.GetInstance().DoConfirm("", "Are you sure you want to upgrade this item ?", "Upgrade", ConfirmUpgrade, Ingame_UIManager.GetInstance().PopupPlecement)


func _on_drop_pressed() -> void:
	PopUpManager.GetInstance().DoConfirm("", "Are you sure you want to drop this item ?", "Drop", ConfirmDrop, Ingame_UIManager.GetInstance().PopupPlecement)
	
	
func ConfirmDrop() -> void:
	ItemDropped.emit(DescribedContainer)
	queue_free()

#@export var RepairButton : Button
#func _on_repair_pressed() -> void:
	#ItemRepaired.emit(DescribedContainer)

func _on_transfer_pressed() -> void:
	ItemTransf.emit(DescribedContainer)
	#queue_free()

func _physics_process(_delta: float) -> void:
	var inv = DescribedContainer.GetParentInventory()
	var TimeLeft = var_to_str(roundi(inv.GetUpgradeTimeLeft()))
	UpgradeLabel.text = "Upgrade time left : {0} minutes".format([TimeLeft])


func _on_add_item_pressed() -> void:
	ItemAdd.emit(DescribedContainer)


func _on_remove_item_pressed() -> void:
	ItemRemove.emit(DescribedContainer)


func _on_add_more_pressed() -> void:
	ItemIncrease.emit(DescribedContainer)

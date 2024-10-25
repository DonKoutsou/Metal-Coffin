extends Control
class_name Inventory

@export var StartingItems : Array[Item]
@export var InventoryBoxScene : PackedScene
@export var InventoryTradeScene : PackedScene
@export var ItemDescriptorScene : PackedScene
@export var Upgrades : Array[Upgrade]
@export var Upgrade_Tab_Scene : PackedScene
@export var ItemNotifScene : PackedScene

var InventoryContents : Array[Inventory_Box] = []
@onready var world: World = $"../.."
@onready var inv_contents: GridContainer = $PanelContainer/HBoxContainer/InvContents
@onready var inventory_ship_stats: InventoryShipStats = $PanelContainer/HBoxContainer/VBoxContainer/Panel/InventoryShipStats

signal OnItemAdded(It : Item)
signal OnItemRemoved(It : Item)
# Called when the node enters the scene tree for the first time.
func GetSaveData() ->SaveData:
	var dat = SaveData.new()
	dat.DataName = "InventoryContents"
	var Datas : Array[Resource] = []
	for g in InventoryContents.size():
		Datas.append(InventoryContents[g].GetSaveData())
	dat.Datas = Datas
	return dat
func LoadSaveData(Data : Array[Resource]) -> void:
	var Items : Array[Item] = []
	for g in Data.size():
		var dat = Data[g] as ItemContainer
		for z in dat.Ammount:
			Items.append(dat.ItemType)
	StartingItems.clear()
	StartingItems.append_array(Items)
func _exit_tree() -> void:
	FlushInventory()
func UpdateSize() -> void:
	var Itms : Array[Item] = []
	for g in InventoryContents.size():
		for z in InventoryContents[g].ItemC.Ammount:
			Itms.append(InventoryContents[g].ItemC.ItemType)
			OnItemRemoved.emit(InventoryContents[g].ItemC.ItemType)
			InventoryContents[g].UpdateAmm(-1)
	for g in inv_contents.get_child_count():
		inv_contents.get_child(g).queue_free()
	InventoryContents.clear()
	for g in ShipData.GetInstance().GetStat("INVENTORY_CAPACITY").GetStat():
		var newbox = InventoryBoxScene.instantiate() as Inventory_Box
		inv_contents.add_child(newbox)
		InventoryContents.append(newbox)
		newbox.connect("ItemUse", OnItemSelected)
	AddItems(Itms, false)
func _ready() -> void:
	set_process(false)
	$PanelContainer.visible = false
	for g in ShipData.GetInstance().GetStat("INVENTORY_CAPACITY").GetStat():
		var newbox = InventoryBoxScene.instantiate() as Inventory_Box
		inv_contents.add_child(newbox)
		InventoryContents.append(newbox)
		newbox.connect("ItemUse", OnItemSelected)
	#for g in Upgrades.size():
	#	var Tab = Upgrade_Tab_Scene.instantiate() as UpgradeTab
	#	$UpgradesContainer/VBoxContainer.add_child(Tab)
	#	Tab.SetData(Upgrades[g])
	#	Tab.connect("OnUgradePressed", TryUpgrade)
	AddItems(StartingItems, false)



func TryUpgrade(UpTab : UpgradeTab) -> void:
	print("Trying to upgrade " + UpTab.UpgradeData.UpgradeName)
	var upgrade : Upgrade
	for g in Upgrades.size():
		if (Upgrades[g].UpgradeName == UpTab.UpgradeData.UpgradeName):
			upgrade = Upgrades[g]
			break
	var UpgradeCost = upgrade.UpgradeItem
	for g in InventoryContents.size():
		if (InventoryContents[g].ItemC.ItemType == UpgradeCost and InventoryContents[g].ItemC.Ammount > 0):
			InventoryContents[g].UpdateAmm(-1)
			UpTab.UpgradeSuccess()
			world.UpgradeStat(UpTab.UpgradeData.UpgradeName, UpTab.UpgradeData.UpgradeStep)
			break
	print("No Materials for Upgrade")

func AddItems(It : Array[Item], Notif = true) -> void:
	var Unplaced : Array[Item] = []
	for z in It.size():
		OnItemAdded.emit(It[z])
		var placed = false
		for g in InventoryContents.size() :
			var box = InventoryContents[g]
			if (box.ItemC.ItemType == It[z]):
				if (box.ItemC.ItemType.MaxStackCount == box.ItemC.Ammount):
					continue
				box.UpdateAmm(1)
				placed = true
				break
		if (placed):
			continue
		for g in InventoryContents.size() :
			var box = InventoryContents[g]
			if (box.IsEmpty()):
				box.RegisterItem(It[z])
				box.UpdateAmm(1)
				placed = true
				break
		if (!placed):
			Unplaced.append(It[z])
	if (Unplaced.size() > 0):
		var TradeScene = InventoryTradeScene.instantiate() as InventoryTrade
		get_parent().add_child(TradeScene)
		var InvItems : Array[Item] = []
		for g in InventoryContents.size():
			var it = InventoryContents[g].ItemC.ItemType
			for z in InventoryContents[g].ItemC.Ammount:
				InvItems.append(it)
		TradeScene.StartTrade(InvItems, Unplaced)
		TradeScene.connect("TradeFinished", TradeFinished)
	inventory_ship_stats.UpdateValues()
	if (Notif):
		if (It.size() == 0):
			return
		var notif = ItemNotifScene.instantiate() as ItemNotif
		notif.AddItems(It)
		get_parent().add_child(notif)
func FlushInventory() -> void:
	for g in InventoryContents.size():
		for z in InventoryContents[g].ItemC.Ammount:
			OnItemRemoved.emit(InventoryContents[g].ItemC.ItemType)
			InventoryContents[g].UpdateAmm(-1)
func TradeFinished(itms : Array[Item]) -> void:
	##FlushInventory()
	var ItmsToAdd : Array[Item] = []
	# itterate through items already in inventory
	for g in InventoryContents.size():
		#if box empty skip it
		if (InventoryContents[g].ItemC.Ammount == 0):
			continue
		#save the item on the specific item box
		var ItToCount = InventoryContents[g].ItemC.ItemType
		#see how many of the item exist in the incomming
		var ItAmm = itms.count(ItToCount)
		#if inventory has the same ammoun of items we skipp this item
		if (ItAmm == InventoryContents[g].ItemC.Ammount):
			for j in ItAmm:
				itms.erase(ItToCount)
			continue
		else : if (ItAmm > InventoryContents[g].ItemC.Ammount):
			for j in ItAmm - InventoryContents[g].ItemC.Ammount:
				ItmsToAdd.append(ItToCount)
		else : if (ItAmm < InventoryContents[g].ItemC.Ammount):
			for j in InventoryContents[g].ItemC.Ammount - ItAmm:
				RemoveItem(ItToCount)
	
	for g in itms.size():
		if (ItmsToAdd.count(itms[g]) == 0):
			for i in itms.count(itms[g]):
				ItmsToAdd.append(itms[g])
	AddItems(ItmsToAdd, false)

func OnItemSelected(It :Item, Amm : int) -> void:
	var descriptors = get_tree().get_nodes_in_group("ItemDescriptor")
	if (descriptors.size() > 0):
		var desc = descriptors[0] as ItemDescriptor
		if (desc.DescribedItem == It):
			descriptors[0].queue_free()
			return
		descriptors[0].queue_free()
	var Descriptor = ItemDescriptorScene.instantiate() as ItemDescriptor
	Descriptor.SetData(It, Amm)
	$DescSpot.add_child(Descriptor)
	Descriptor.connect("ItemUsed", UseItem)
	Descriptor.connect("ItemUpgraded", UpgradeItem)
	Descriptor.connect("ItemDropped", RemoveItem)
func UpgradeItem(Part : ShipPart) -> void:
	var UpgradeSuccess = false
	var UpItem = Part.UpgradeItems[0]
	for g in InventoryContents.size():
		if (InventoryContents[g].ItemC.ItemType == UpItem):
			if (InventoryContents[g].ItemC.Ammount >= Part.UpgradeItems.size()):
				RemoveItem(Part)
				for z in Part.UpgradeItems.size():
					RemoveItem(UpItem)
				AddItems([Part.UpgradeVersion], false)
				OnItemSelected(Part.UpgradeVersion, 1)
				UpgradeSuccess = true
	if (!UpgradeSuccess) :
		var pop = AcceptDialog.new()
		pop.dialog_text = "Not enough upgrade materials to complete action"
		add_child(pop)
		pop.popup_centered()
func RemoveItem(It : Item):
	for g in InventoryContents.size():
		var box = InventoryContents[g]
		if (box.ItemC.ItemType == It):
			box.UpdateAmm(-1)
			OnItemRemoved.emit(It)
			inventory_ship_stats.UpdateValues()
			return
func UseItem(It : Item, Times : int = 1):
	for z in Times:
		if (world.UseItem(It)):
			for g in InventoryContents.size():
				var box = InventoryContents[g]
				if (box.ItemC.ItemType == It):
					box.UpdateAmm(-1)
					OnItemRemoved.emit(It)
					if (box.ItemC.Ammount == 0):
						var descriptors = get_tree().get_nodes_in_group("ItemDescriptor")
						if (descriptors.size() > 0):
							descriptors[0].queue_free()
					break
		else :
			return
	#Icon = TextureRect.new()
	#Icon.texture = It.ItemIcon
	#get_parent().add_child(Icon)
	#set_process(true)
func UpdateShipInfo(ship : BaseShip) -> void:
	$PanelContainer/HBoxContainer/VBoxContainer/HBoxContainer/TextureRect.texture = ship.Icon
	$PanelContainer/HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/Label.text = ship.ShipName
	$PanelContainer/HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/Label2.text = ship.ShipDesc
#var Icon : TextureRect
#func _process(delta: float) -> void:
#	if (Input.is_action_pressed("Click")):
#		Icon.global_position = get_global_mouse_position()
#	else:
#		set_process(false)
#		Icon.queue_free()
func _on_inventory_button_pressed() -> void:
	var IsOpening = !$PanelContainer.visible
	$PanelContainer.visible = IsOpening
	if (IsOpening):
		inventory_ship_stats.UpdateValues()
	if (!IsOpening):
		var descriptors = get_tree().get_nodes_in_group("ItemDescriptor")
		if (descriptors.size() > 0):
			descriptors[0].queue_free()
func _on_upgrades_button_pressed() -> void:
	$UpgradesContainer.visible = !$UpgradesContainer.visible

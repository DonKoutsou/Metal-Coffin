extends Control
class_name Inventory

@export var StartingItems : Array[Item]
@export var LoadedItems :Array[Item]

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
signal OnShipPartDamaged(Part : ShipPart)
signal OnShipPartFixed(Part : ShipPart)
signal OnInventoryOpened()
signal OnInvencotyClosed()
var Loading = false
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
	LoadedItems.append_array(Items)
	Loading = true
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
	if ((ShipData.GetInstance().GetStat("INVENTORY_CAPACITY").GetStat() as int) % 2 != 0):
		inv_contents.columns = 3
	else :
		inv_contents.columns = 4
		
func _ready() -> void:
	set_process(false)
	$PanelContainer.visible = false
	for g in ShipData.GetInstance().GetStat("INVENTORY_CAPACITY").GetStat():
		var newbox = InventoryBoxScene.instantiate() as Inventory_Box
		inv_contents.add_child(newbox)
		InventoryContents.append(newbox)
		newbox.connect("ItemUse", OnItemSelected)
	if ((ShipData.GetInstance().GetStat("INVENTORY_CAPACITY").GetStat() as int) % 2 != 0):
		inv_contents.columns = 3
	#for g in Upgrades.size():
	#	var Tab = Upgrade_Tab_Scene.instantiate() as UpgradeTab
	#	$UpgradesContainer/VBoxContainer.add_child(Tab)
	#	Tab.SetData(Upgrades[g])
	#	Tab.connect("OnUgradePressed", TryUpgrade)
	if (Loading):
		AddItems(LoadedItems, false)
	else :
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
				if (box.ItemC.Ammount >= box.ItemC.ItemType.MaxStackCount):
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
	FlushInventory()
	AddItems(itms, false)

func OnItemSelected(ItCo : ItemContainer) -> void:
	var descriptors = get_tree().get_nodes_in_group("ItemDescriptor")
	if (descriptors.size() > 0):
		var desc = descriptors[0] as ItemDescriptor
		if (desc.DescribedContainer == ItCo):
			descriptors[0].queue_free()
			return
		descriptors[0].queue_free()
	var Descriptor = ItemDescriptorScene.instantiate() as ItemDescriptor
	Descriptor.SetData(ItCo)
	$DescSpot.add_child(Descriptor)
	Descriptor.connect("ItemUsed", UseItem)
	Descriptor.connect("ItemUpgraded", UpgradeItem)
	Descriptor.connect("ItemDropped", RemoveItem)
	Descriptor.connect("ItemRepaired", RepairPart)
	
func UpgradeItem(Cont : ItemContainer) -> void:
	var UpgradeSuccess = false
	var Part = Cont.ItemType
	var UpItem = Part.UpgradeItems[0]
	for g in InventoryContents.size():
		if (InventoryContents[g].ItemC.ItemType == UpItem):
			if (InventoryContents[g].ItemC.Ammount >= Part.UpgradeItems.size()):
				RemoveItem(Cont)
				for z in Part.UpgradeItems.size():
					RemoveItem(InventoryContents[g].ItemC)
				Part.UpgradeVersion.CurrentVal = Part.CurrentVal
				AddItems([Part.UpgradeVersion], false)
				#OnItemSelected(InventoryContents[g].ItemC)
				var descriptors = get_tree().get_nodes_in_group("ItemDescriptor")
				if (descriptors.size() > 0):
					descriptors[0].queue_free()
				UpgradeSuccess = true
				break
	if (!UpgradeSuccess) :
		PopUpManager.GetInstance().DoPopUp("Not enough upgrade materials to complete action")
		
func RemoveItem(Cont : ItemContainer):
	for g in InventoryContents.size():
		var box = InventoryContents[g]
		if (box.ItemC == Cont):
			OnItemRemoved.emit(Cont.ItemType)
			inventory_ship_stats.UpdateValues()
			box.UpdateAmm(-1)
			return
			
func UseItem(Cont : ItemContainer, Times : int = 1):
	for z in Times:
		if (world.UseItem(Cont.ItemType)):
			for g in InventoryContents.size():
				if (InventoryContents[g].ItemC == Cont):
					var box = InventoryContents[g]
					OnItemRemoved.emit(Cont.ItemType)
					box.UpdateAmm(-1)
					if (box.ItemC.Ammount == 0):
						var descriptors = get_tree().get_nodes_in_group("ItemDescriptor")
						if (descriptors.size() > 0):
							descriptors[0].queue_free()
					break
					
func RepairPart(Cont : ItemContainer) -> void:
	var RepairSuccess = false
	var Part = Cont.ItemType
	var RepairItem = Part.RepairItems[0]
	for g in InventoryContents.size():
		if (InventoryContents[g].ItemC.ItemType == RepairItem):
			if (InventoryContents[g].ItemC.Ammount >= Part.RepairItems.size()):
				for z in Part.RepairItems.size():
					RemoveItem(InventoryContents[g].ItemC)
				Part.IsDamaged = false
				var descriptors = get_tree().get_nodes_in_group("ItemDescriptor")
				if (descriptors.size() > 0):
					descriptors[0].queue_free()
				RepairSuccess = true
				OnShipPartFixed.emit(Part)
				break
	if (!RepairSuccess) :
		PopUpManager.GetInstance().DoPopUp("Not enough upgrade materials to complete action")
	else:
		for g in InventoryContents.size():
			if (InventoryContents[g].ItemC == Cont):
				InventoryContents[g].UpdateDamaged(false)
				
func BreakPart(Part : ShipPart) -> void:
	for g in InventoryContents.size():
			if (InventoryContents[g].ItemC.ItemType == Part):
				InventoryContents[g].UpdateDamaged(true)
	Part.IsDamaged = false
	OnShipPartDamaged.emit(Part)
	
func UpdateShipInfo(ship : BaseShip) -> void:
	$PanelContainer/HBoxContainer/VBoxContainer/HBoxContainer/TextureRect.texture = ship.Icon
	$PanelContainer/HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/Label.text = ship.ShipName
	$PanelContainer/HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/Label2.text = ship.ShipDesc

func _on_inventory_button_pressed() -> void:
	var IsOpening = !$PanelContainer.visible
	$PanelContainer.visible = IsOpening
	if (IsOpening):
		OnInventoryOpened.emit()
		inventory_ship_stats.UpdateValues()
	if (!IsOpening):
		OnInvencotyClosed.emit()
		var descriptors = get_tree().get_nodes_in_group("ItemDescriptor")
		if (descriptors.size() > 0):
			descriptors[0].queue_free()
			
func _on_upgrades_button_pressed() -> void:
	$UpgradesContainer.visible = !$UpgradesContainer.visible

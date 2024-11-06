extends Control
class_name Inventory

@export var StartingItems : Array[Item]
@export var LoadedItems :Array[Item]

@export var InventoryBoxScene : PackedScene
@export var InventoryTradeScene : PackedScene
@export var ItemDescriptorScene : PackedScene
@export var ItemNotifScene : PackedScene

var InventoryContents : Array[Inventory_Box] = []
static var Instance : Inventory

@onready var inv_contents: GridContainer = $HBoxContainer/InvContents
@onready var inventory_ship_stats: InventoryShipStats = $HBoxContainer/VBoxContainer/Panel/InventoryShipStats

signal INV_OnItemAdded(It : Item)
signal INV_OnItemRemoved(It : Item)
signal INV_OnShipPartDamaged(Part : ShipPart)
signal INV_OnShipPartFixed(Part : ShipPart)
signal INV_OnInventoryOpened()
signal INV_OnInvencotyClosed()
signal INV_OnItemUsed(It : UsableItem)
var Loading = false

static func GetInstance() -> Inventory:
	return Instance
	
func _ready() -> void:
	set_process(false)
	visible = false
	Instance = self
	for g in ShipData.GetInstance().GetStat("INVENTORY_CAPACITY").GetStat():
		var newbox = InventoryBoxScene.instantiate() as Inventory_Box
		inv_contents.add_child(newbox)
		InventoryContents.append(newbox)
		newbox.connect("ItemUse", _OnItemSelected)
	if ((ShipData.GetInstance().GetStat("INVENTORY_CAPACITY").GetStat() as int) % 2 != 0):
		inv_contents.columns = 3
	if (Loading):
		AddItems(LoadedItems, false)
	else :
		AddItems(StartingItems, false)
		
func _exit_tree() -> void:
	FlushInventory()
	
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

func UpdateSize() -> void:
	var Itms : Array[Item] = []
	for g in InventoryContents.size():
		for z in InventoryContents[g].ItemC.Ammount:
			Itms.append(InventoryContents[g].ItemC.ItemType)
			INV_OnItemRemoved.emit(InventoryContents[g].ItemC.ItemType)
			InventoryContents[g].UpdateAmm(-1)
	for g in inv_contents.get_child_count():
		inv_contents.get_child(g).queue_free()
	InventoryContents.clear()
	for g in ShipData.GetInstance().GetStat("INVENTORY_CAPACITY").GetStat():
		var newbox = InventoryBoxScene.instantiate() as Inventory_Box
		inv_contents.add_child(newbox)
		InventoryContents.append(newbox)
		newbox.connect("ItemUse", _OnItemSelected)
	AddItems(Itms, false)
	if ((ShipData.GetInstance().GetStat("INVENTORY_CAPACITY").GetStat() as int) % 2 != 0):
		inv_contents.columns = 3
	else :
		inv_contents.columns = 4

func GetItemForStat(StatN : String) -> ItemContainer:
	for g in InventoryContents:
		if g.ItemC.ItemType is UsableItem and g.ItemC.Ammount > 0:
			var usit = g.ItemC.ItemType as UsableItem
			if (usit.StatUseName == StatN):
				return g.ItemC
	return null

func AddItems(It : Array[Item], Notif = true) -> void:
	var Unplaced : Array[Item] = []
	var Placed : Array[Item] = []
	for z in It.size():
		var placed = false
		for g in InventoryContents.size():
			var box = InventoryContents[g]
			if (box.ItemC.ItemType == It[z]):
				if (box.ItemC.Ammount >= box.ItemC.ItemType.MaxStackCount):
					continue
				box.UpdateAmm(1)
				placed = true
				break
		if (placed):
			Placed.append(It[z])
			continue
		for g in InventoryContents.size():
			var box = InventoryContents[g]
			if (box.IsEmpty()):
				box.RegisterItem(It[z])
				box.UpdateAmm(1)
				placed = true
				break
		if (!placed):
			Unplaced.append(It[z])
		else:
			INV_OnItemAdded.emit(It[z])

	if (Unplaced.size() > 0):
		if (visible):
			visible = false
			INV_OnInvencotyClosed.emit()
			FindAndDissableDescriptors()
		if (get_tree().get_nodes_in_group("InventoryTrade").size() > 0):
			var trade = get_tree().get_nodes_in_group("InventoryTrade")[0] as InventoryTrade
			trade.UpdateDrops(Unplaced)
		else : 
			var TradeScene = InventoryTradeScene.instantiate() as InventoryTrade
			Ingame_UIManager.GetInstance().AddUI(TradeScene, false)
			var InvItems : Array[Item] = []
			for g in InventoryContents.size():
				var it = InventoryContents[g].ItemC.ItemType
				for z in InventoryContents[g].ItemC.Ammount:
					InvItems.append(it)
			TradeScene.StartTrade(InvItems, Unplaced)
			TradeScene.connect("TradeFinished", _TradeFinished)
	if (Placed.size() > 0 and get_tree().get_nodes_in_group("InventoryTrade").size() > 0):
		var trade = get_tree().get_nodes_in_group("InventoryTrade")[0] as InventoryTrade
		trade.UpdateInventoryContents(Placed)
		
	inventory_ship_stats.UpdateValues()
	if (Notif):
		if (It.size() == 0):
			return
		var notif
		if (get_tree().get_nodes_in_group("ItemNotification").size() == 0):
			notif = ItemNotifScene.instantiate() as ItemNotif
			Ingame_UIManager.GetInstance().AddUI(notif)
		else :
			notif = get_tree().get_nodes_in_group("ItemNotification")[0]
		notif.AddItems(It)
		
func FlushInventory() -> void:
	for g in InventoryContents.size():
		for z in InventoryContents[g].ItemC.Ammount:
			INV_OnItemRemoved.emit(InventoryContents[g].ItemC.ItemType)
			InventoryContents[g].UpdateAmm(-1)
func _TradeFinished(itms : Array[Item]) -> void:
	FlushInventory()
	AddItems(itms, false)
	
func _OnItemSelected(ItCo : ItemContainer) -> void:
	var descriptors = get_tree().get_nodes_in_group("ItemDescriptor")
	if (descriptors.size() > 0):
		var desc = descriptors[0] as ItemDescriptor
		if (desc.DescribedContainer == ItCo):
			descriptors[0].queue_free()
			$HBoxContainer/VBoxContainer/HBoxContainer.visible = true
			return
		descriptors[0].queue_free()
	var Descriptor = ItemDescriptorScene.instantiate() as ItemDescriptor
	Descriptor.SetData(ItCo)
	$HBoxContainer/VBoxContainer.add_child(Descriptor)
	$HBoxContainer/VBoxContainer.move_child(Descriptor, 0)
	$HBoxContainer/VBoxContainer/HBoxContainer.visible = false
	Descriptor.connect("ItemUsed", UseItem)
	Descriptor.connect("ItemUpgraded", UpgradeItem)
	Descriptor.connect("ItemDropped", RemoveItem)
	Descriptor.connect("ItemRepaired", RepairPart)
	
func FindAndDissableDescriptors() -> void:
	var descriptors = get_tree().get_nodes_in_group("ItemDescriptor")
	if (descriptors.size() > 0):
		descriptors[0].queue_free()
	$HBoxContainer/VBoxContainer/HBoxContainer.visible = true
	
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
				FindAndDissableDescriptors()
				UpgradeSuccess = true
				break
	if (!UpgradeSuccess) :
		PopUpManager.GetInstance().DoPopUp("Not enough upgrade materials to complete action")
		
func RemoveItem(Cont : ItemContainer):
	for g in InventoryContents.size():
		var box = InventoryContents[g]
		if (box.ItemC == Cont):
			INV_OnItemRemoved.emit(Cont.ItemType)
			inventory_ship_stats.UpdateValues()
			box.UpdateAmm(-1)
			return
			
func UseItem(Cont : ItemContainer, Times : int = 1):
	for z in Times:
		if (TryUseItem(Cont.ItemType)):
			for g in InventoryContents.size():
				if (InventoryContents[g].ItemC == Cont):
					var box = InventoryContents[g]
					INV_OnItemRemoved.emit(Cont.ItemType)
					box.UpdateAmm(-1)
					if (box.ItemC.Ammount == 0):
						FindAndDissableDescriptors()
					break
					
func TryUseItem(It : UsableItem) -> bool:
	var statname = It.StatUseName
	var dat = ShipData.GetInstance()
	if (dat.GetStat(statname).GetCurrentValue() == dat.GetStat(statname).GetStat()):
		PopUpManager.GetInstance().DoPopUp(statname + " is already full")
		return false
	else :
		INV_OnItemUsed.emit(It)
		return true
		
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
				FindAndDissableDescriptors()
				RepairSuccess = true
				INV_OnShipPartFixed.emit(Part)
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
	INV_OnShipPartDamaged.emit(Part)
	
func UpdateShipInfo(ship : BaseShip) -> void:
	$HBoxContainer/VBoxContainer/HBoxContainer/TextureRect.texture = ship.Icon
	$HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/Label.text = ship.ShipName
	$HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/Label2.text = ship.ShipDesc
	
func _on_inventory_button_pressed() -> void:
	var IsOpening = !visible
	visible = IsOpening
	if (IsOpening):
		INV_OnInventoryOpened.emit()
		inventory_ship_stats.UpdateValues()
	if (!IsOpening):
		INV_OnInvencotyClosed.emit()
		FindAndDissableDescriptors()
		
func ForceCloseInv():
	if (!visible):
		return
	visible = false
	INV_OnInvencotyClosed.emit()
	FindAndDissableDescriptors()
	
func _on_upgrades_button_pressed() -> void:
	$UpgradesContainer.visible = !$UpgradesContainer.visible

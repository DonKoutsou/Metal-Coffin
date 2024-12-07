extends Control
class_name Inventory

@export var StartingItems : Array[Item]
@export var LoadedItems :Array[Item]
@export var MissileDockEventH : MissileDockEventHandler
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
	

func OnSimulationPaused(t : bool) -> void:
	$UpgradeTimer.paused = t

func _ready() -> void:
	MissileDockEventH.connect("MissileLaunched", RemoveItemSimp)
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
		# calling later to make sure inventory size buffs from captains are applied beforehand
		call_deferred("AddItems", LoadedItems, false)
		#AddItems(LoadedItems, false)
	else :
		AddItems(StartingItems, false)

func ToggleShipPausing(t : bool):
	$"../HBoxContainer/Panel3/InventoryButton".disabled = t
	get_tree().call_group("Ships", "TogglePause", t)
	
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
	for Itm in It:
		var placed = FindMatchingBoxForItAndPlace(Itm)
		if (placed):
			Placed.append(Itm)
			continue
		placed = FindEmptyBoxForItAndPlace(Itm)
		if (!placed):
			Unplaced.append(Itm)
	#HANDLE ITEMS THAT COULDN'T BE PLACED IN INVENTORY BY INITIALIZING A TRADE TO PLAYER CAN CHOOSE WHAT TO KEEP
	if (Unplaced.size() > 0):
		if (visible):
			visible = false
			INV_OnInvencotyClosed.emit()
			FindAndDissableDescriptors()
		#COMMENTED OUT OF UPDATING TRADE SCENE WITH NEW ITEMS SINCE SIMULATION IS PAUSED WHEN TRADING 
		#SO NO NEW ITEMS SHOULD BE AQCIRED WHILE TRADING
		#if (get_tree().get_nodes_in_group("InventoryTrade").size() > 0):
			#var trade = get_tree().get_nodes_in_group("InventoryTrade")[0] as InventoryTrade
			#trade.UpdateDrops(Unplaced)
		#else :
		InitiateTrade(Unplaced)
	#if (Placed.size() > 0 and get_tree().get_nodes_in_group("InventoryTrade").size() > 0):
		#var trade = get_tree().get_nodes_in_group("InventoryTrade")[0] as InventoryTrade
		#trade.UpdateInventoryContents(Placed)
		
	inventory_ship_stats.UpdateValues()
	if (Notif):
		DoItemNotif(Placed)
#////////////////////////////////////////////////////
func FindMatchingBoxForItAndPlace(it : Item) -> bool:
	for content in InventoryContents:
		var box = content
		if (box.ItemC.Ammount == 0):
			continue
		#check if box has same items as us
		if (box.ItemC.ItemType.ItemName == it.ItemName):
			#check if box can fit more
			if (box.ItemC.Ammount >= box.ItemC.ItemType.MaxStackCount):
				continue
			box.UpdateAmm(1)
			print("Added item : " + it.ItemName)
			INV_OnItemAdded.emit(it)
			if (it is MissileItem):
				MissileDockEventH.emit_signal("MissileAdded", it)
			return true
	return false
func FindEmptyBoxForItAndPlace(it : Item) -> bool:
	for content in InventoryContents:
		var box = content
		if (box.IsEmpty()):
			box.RegisterItem(it)
			box.UpdateAmm(1)
			print("Added item : " + it.ItemName)
			INV_OnItemAdded.emit(it)
			if (it is MissileItem):
				MissileDockEventH.emit_signal("MissileAdded", it)
			return true
	return false
#////////////////////////////////////////////////////
func InitiateTrade(UnplacedItms : Array[Item]):
	var TradeScene = InventoryTradeScene.instantiate() as InventoryTrade
	Ingame_UIManager.GetInstance().AddUI(TradeScene, false, true)
	var InvItems : Array[Item] = []
	for g in InventoryContents.size():
		var it = InventoryContents[g].ItemC.ItemType
		for z in InventoryContents[g].ItemC.Ammount:
			InvItems.append(it)
	ToggleShipPausing(true)
	TradeScene.StartTrade(InvItems, UnplacedItms)
	TradeScene.connect("TradeFinished", _TradeFinished)

func DoItemNotif(its : Array[Item]):
	if (its.size() == 0):
			return
	var notif
	if (get_tree().get_nodes_in_group("ItemNotification").size() == 0):
		notif = ItemNotifScene.instantiate() as ItemNotif
		Ingame_UIManager.GetInstance().AddUI(notif, false, true)
	else :
		notif = get_tree().get_nodes_in_group("ItemNotification")[0]
	notif.AddItems(its)

func FlushInventory() -> void:
	for g in InventoryContents.size():
		for z in InventoryContents[g].ItemC.Ammount:
			INV_OnItemRemoved.emit(InventoryContents[g].ItemC.ItemType)
			print("Removed item : " + InventoryContents[g].ItemC.ItemType.ItemName)
			InventoryContents[g].UpdateAmm(-1)
func _TradeFinished(itms : Array[Item]) -> void:
	ToggleShipPausing(false)
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
		descriptors[0].SetData(ItCo)
		return
	var Descriptor = ItemDescriptorScene.instantiate() as ItemDescriptor
	$HBoxContainer/VBoxContainer.add_child(Descriptor)
	$HBoxContainer/VBoxContainer.move_child(Descriptor, 0)
	$HBoxContainer/VBoxContainer/HBoxContainer.visible = false
	Descriptor.SetData(ItCo)
	Descriptor.connect("ItemUsed", UseItem)
	Descriptor.connect("ItemUpgraded", UpgradeItem)
	Descriptor.connect("ItemDropped", RemoveItem)
	Descriptor.connect("ItemRepaired", RepairPart)
	
func FindAndDissableDescriptors() -> void:
	var descriptors = get_tree().get_nodes_in_group("ItemDescriptor")
	if (descriptors.size() > 0):
		descriptors[0].queue_free()
	$HBoxContainer/VBoxContainer/HBoxContainer.visible = true

var UpgradedItem : ItemContainer
func CancelUpgrades() -> void:
	UpgradedItem = null
	$UpgradeTimer.stop()
func UpgradeItem(Cont : ItemContainer) -> void:
	#var UpgradeSuccess = false
	if (UpgradedItem != null):
		PopUpManager.GetInstance().DoFadeNotif("Ship is already upgrading a part. Wait for it to finish first.")
		return
	if (PlayerShip.GetInstance().CurrentPort == null):
		PopUpManager.GetInstance().DoFadeNotif("Ship needs to be docked to upgrade")
		return
	else :if (!PlayerShip.GetInstance().CanUpgrade):
		PopUpManager.GetInstance().DoFadeNotif("Cant upgrade ship in current port.")
		return
	var Part = Cont.ItemType as ShipPart
	var UpTime = Part.UpgradeTime
	$UpgradeTimer.wait_time = UpTime
	$UpgradeTimer.start()
	UpgradedItem = Cont
	FindAndDissableDescriptors()
	#for g in InventoryContents.size():
		#if (InventoryContents[g].ItemC.ItemType == UpItem):
			#if (InventoryContents[g].ItemC.Ammount >= Part.UpgradeItems.size()):
				#RemoveItem(Cont)
				#for z in Part.UpgradeItems.size():
					#RemoveItem(InventoryContents[g].ItemC)
				#Part.UpgradeVersion.CurrentVal = Part.CurrentVal
				#AddItems([Part.UpgradeVersion], false)
				#FindAndDissableDescriptors()
				#UpgradeSuccess = true
				#break
	#if (!UpgradeSuccess) :
		#PopUpManager.GetInstance().DoPopUp("Not enough upgrade materials to complete action")
func ItemUpgradeFinished() -> void:
	var Part = UpgradedItem.ItemType as ShipPart
	#for z in Part.UpgradeItems.size():
		#RemoveItem(InventoryContents[g].ItemC)
	RemoveItem(UpgradedItem)
	Part.UpgradeVersion.CurrentVal = Part.CurrentVal
	AddItems([Part.UpgradeVersion], false)
	UpgradedItem = null
	#FindAndDissableDescriptors()

func GetUpgradeTimeLeft() -> float:
	return $UpgradeTimer.time_left

func RemoveItem(Cont : ItemContainer):
	for g in InventoryContents.size():
		var box = InventoryContents[g]
		if (box.ItemC == Cont):
			INV_OnItemRemoved.emit(Cont.ItemType)
			print("Removed item : " + Cont.ItemType.ItemName)
			inventory_ship_stats.UpdateValues()
			box.UpdateAmm(-1)
			if (Cont.ItemType is MissileItem):
				MissileDockEventH.emit("MissileRemoved")
			return
func RemoveItemSimp(It : Item):
	for g in InventoryContents.size():
		var box = InventoryContents[g]
		if (box.ItemC.ItemType == It):
			INV_OnItemRemoved.emit(It)
			print("Removed item : " + It.ItemName)
			inventory_ship_stats.UpdateValues()
			box.UpdateAmm(-1)
			if (It is MissileItem):
				MissileDockEventH.emit_signal("MissileRemoved", It)
			return
func UseItem(Cont : ItemContainer, Times : int = 1):
	for z in Times:
		if (TryUseItem(Cont.ItemType)):
			RemoveItem(Cont)
			#for g in InventoryContents.size():
			#	if (InventoryContents[g].ItemC == Cont):
			#		var box = InventoryContents[g]	
			#		INV_OnItemRemoved.emit(Cont.ItemType)
			#		box.UpdateAmm(-1)
			#		if (box.ItemC.Ammount == 0):
			#			FindAndDissableDescriptors()
			#		break
					
func TryUseItem(It : UsableItem) -> bool:
	var statname = It.StatUseName
	var dat = ShipData.GetInstance()
	if (dat.GetStat(statname).GetCurrentValue() == dat.GetStat(statname).GetStat()):
		PopUpManager.GetInstance().DoPopUp(statname + " is already full")
		return false
	else :
		INV_OnItemUsed.emit(It)
		print("Used item : " + It.ItemName)
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
		$"../CaptainUI".visible = false
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

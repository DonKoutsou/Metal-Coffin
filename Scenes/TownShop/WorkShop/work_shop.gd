extends Control

class_name WorkShop

@export var ShipButtonsParent : Control

@export var EngineInventoryBoxParent : Control
@export var SensorInventoryBoxParent : Control
@export var FuelTankInventoryBoxParent : Control
@export var WeaponInventoryBoxParent : Control
@export var ShieldInventoryBoxParent : Control
@export var DescriptorPlace : Control
@export var WorkshopItemUI : PackedScene
@export var ItemDescriptorScene : PackedScene
@export var InventoryBoxScene : PackedScene
@export var StatComp : PackedScene
@export var ItemParent : Control
@export var ItemCat : Control
@export var ShipStats : CaptainStatContainer
@export var Descr : ItemDescriptor

var CurrentShip : MapShip
var WorkShopMerch : Array[Merchandise]
var WorkshopDescriptor : ItemDescriptor
var HasUpgradeBuff : bool = false

signal WorkshopClosed
signal ShipSold(Ship : MapShip)

var AvailableShips : Array[MapShip]

func _physics_process(_delta: float) -> void:
	#Going through and seeing wich Merch is closer to middle of screen and connect UI Descriptor to it
	var midpoint = get_viewport_rect().size/2
	var Closest : Control
	var Dist : float = 99999999999999
	for g : Control in ItemParent.get_children():
		if (g is not WorkShopItem):
			continue
		var NewDest = (g.global_position + (g.size / 2)).distance_squared_to(midpoint)
		if (NewDest < Dist):
			Dist = NewDest
			Closest = g
	if (Closest == null):
		return
	if (Descr.DescribedItem != Closest.It):
		Descr.SetMerchData(Closest.It, [], true)

func Init(Ships : Array[MapShip], HasUpgrade : bool, Merch : Array[Merchandise]) -> void:
	HasUpgradeBuff = HasUpgrade
	WorkShopMerch = Merch
	for g in Ships:
		var b = Button.new()
		ShipButtonsParent.add_child(b)
		b.text = g.Cpt.GetCaptainName()
		b.pressed.connect(OnShipSelected.bind(g))
	AvailableShips = Ships
	OnShipSelected(Ships[0])

func RefreshCaptains() -> void:
	for g in ShipButtonsParent.get_children():
		g.queue_free()
		
	for g in AvailableShips:
		var b = Button.new()
		ShipButtonsParent.add_child(b)
		b.text = g.Cpt.GetCaptainName()
		b.pressed.connect(OnShipSelected.bind(g))
		
	OnShipSelected(AvailableShips[0])

func OnShipSelected(Ship : MapShip) -> void:
	if (Ship == CurrentShip):
		return
	
	CloseDescriptor()
	
	CurrentShip = Ship
	
	for g in EngineInventoryBoxParent.get_children():
		g.free()
	for g in SensorInventoryBoxParent.get_children():
		g.free()
	for g in FuelTankInventoryBoxParent.get_children():
		g.free()
	for g in WeaponInventoryBoxParent.get_children():
		g.free()
	for g in ShieldInventoryBoxParent.get_children():
		g.free()
	
	ShipStats.SetCaptain(Ship.Cpt)
	ShipStats.ShowStats()
	#ShipIcons.texture = Ship.Cpt.ShipIcon
	
	var Cha = Ship.Cpt
	
	var CharEngineSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.ENGINES_SLOTS)
	var CharSensorSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.SENSOR_SLOTS)
	var CharFuelTankSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK_SLOTS)
	var CharShieldSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.SHIELD_SLOTS)
	var CharWeaponSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.WEAPON_SLOTS)
	
	for g in CharEngineSpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		EngineInventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
		Box.Enable()
		#EngineInventoryBoxParent.columns = min(2, CharEngineSpace)
	
	for g in CharSensorSpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		SensorInventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
		Box.Enable()
		#SensorInventoryBoxParent.columns = min(2, CharSensorSpace)
	
	for g in CharFuelTankSpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		FuelTankInventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
		Box.Enable()
		#FuelTankInventoryBoxParent.columns = min(2, CharFuelTankSpace)
	
	for g in CharShieldSpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		ShieldInventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
		Box.Enable()
		#ShieldInventoryBoxParent.columns = min(2, CharShieldSpace)
	
	for g in CharWeaponSpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		WeaponInventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
		Box.Enable()
		#WeaponInventoryBoxParent.columns = min(2, CharWeaponSpace)
	
	var inv = Cha.GetCharacterInventory()
	
	for g in inv.GetInventoryContents():
		if (g is ShipPart):
			for box : Inventory_Box in GetBoxParentForType(g.PartType).get_children():
				if box.IsEmpty():
					box.RegisterItem(g)
					box.UpdateAmm(1)
					break

func RefreshInventory() -> void:
	for g in EngineInventoryBoxParent.get_children():
		g.free()
	for g in SensorInventoryBoxParent.get_children():
		g.free()
	for g in FuelTankInventoryBoxParent.get_children():
		g.free()
	for g in WeaponInventoryBoxParent.get_children():
		g.free()
	for g in ShieldInventoryBoxParent.get_children():
		g.free()
	
	ShipStats.SetCaptain(CurrentShip.Cpt)
	ShipStats.ShowStats()
	#ShipIcons.texture = CurrentShip.Cpt.ShipIcon
	
	var Cha = CurrentShip.Cpt
	
	var CharEngineSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.ENGINES_SLOTS)
	var CharSensorSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.SENSOR_SLOTS)
	var CharFuelTankSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK_SLOTS)
	var CharShieldSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.SHIELD_SLOTS)
	var CharWeaponSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.WEAPON_SLOTS)
	
	for g in CharEngineSpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		EngineInventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
		Box.Enable()
		#EngineInventoryBoxParent.columns = min(2, CharEngineSpace)
	
	for g in CharSensorSpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		SensorInventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
		Box.Enable()
		#SensorInventoryBoxParent.columns = min(2, CharSensorSpace)
	
	for g in CharFuelTankSpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		FuelTankInventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
		Box.Enable()
		#FuelTankInventoryBoxParent.columns = min(2, CharFuelTankSpace)
	
	for g in CharShieldSpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		ShieldInventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
		Box.Enable()
		#ShieldInventoryBoxParent.columns = min(2, CharShieldSpace)
	
	for g in CharWeaponSpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		WeaponInventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
		Box.Enable()
		#WeaponInventoryBoxParent.columns = min(2, CharWeaponSpace)
	
	var inv = Cha.GetCharacterInventory()
	var Contents = inv.GetInventoryContents()
	for g in Contents:
		if (g is ShipPart):
			for z in Contents[g]:
				for box : Inventory_Box in GetBoxParentForType(g.PartType).get_children():
					if box.IsEmpty():
						box.RegisterItem(g)
						box.UpdateAmm(1)
						break

func GetBoxParentForType(PartType : ShipPart.ShipPartType) -> Control:
	var BoxParent : Control
	if (PartType == ShipPart.ShipPartType.ENGINE):
		BoxParent = EngineInventoryBoxParent
	else : if (PartType == ShipPart.ShipPartType.SENSOR):
		BoxParent = SensorInventoryBoxParent
	else : if (PartType == ShipPart.ShipPartType.FUEL_TANK):
		BoxParent = FuelTankInventoryBoxParent
	else : if (PartType == ShipPart.ShipPartType.WEAPON):
		BoxParent = WeaponInventoryBoxParent
	else : if (PartType == ShipPart.ShipPartType.SHIELD):
		BoxParent = ShieldInventoryBoxParent
	return BoxParent

func GetTypeOfBox(Box : Inventory_Box) -> ShipPart.ShipPartType:
	var BoxParent = Box.get_parent()
	var Type : ShipPart.ShipPartType
	if (BoxParent == EngineInventoryBoxParent):
		Type = ShipPart.ShipPartType.ENGINE
	else : if (BoxParent == SensorInventoryBoxParent):
		Type = ShipPart.ShipPartType.SENSOR
	else : if (BoxParent == FuelTankInventoryBoxParent):
		Type = ShipPart.ShipPartType.FUEL_TANK
	else : if (BoxParent == WeaponInventoryBoxParent):
		Type = ShipPart.ShipPartType.WEAPON
	else : if (BoxParent == ShieldInventoryBoxParent):
		Type = ShipPart.ShipPartType.SHIELD
	return Type

func ItemSelected(Box : Inventory_Box) -> void:
	
	if (WorkshopDescriptor != null):
		DescriptorPlace.remove_child(WorkshopDescriptor)
		WorkshopDescriptor.queue_free()
		if (WorkshopDescriptor.DescribedContainer == Box):
			ShipStats.get_parent().visible = true
			return
	
			
	WorkshopDescriptor= ItemDescriptorScene.instantiate() as ItemDescriptor
	WorkshopDescriptor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ShipStats.get_parent().visible = false
	WorkshopDescriptor.DescribedContainer = Box
	if (Box.IsEmpty()):
		WorkshopDescriptor.SetEmptyShopData(GetTypeOfBox(Box))
		WorkshopDescriptor.connect("ItemAdd", AddItem)
	else:
		WorkshopDescriptor.SetWorkShopData(Box, HasUpgradeBuff, CurrentShip.Cpt)
		WorkshopDescriptor.connect("ItemAdd", AddItem)
		WorkshopDescriptor.connect("ItemRemove", RemoveItem)
		WorkshopDescriptor.connect("ItemUpgraded", UpgradeItem)
		
		#Descriptor.connect("ItemDropped", OwnerInventory.RemoveItemFromBox)
		#Descriptor.connect("ItemTransf", ItemTranfer)
	DescriptorPlace.add_child(WorkshopDescriptor)
	WorkshopDescriptor.set_physics_process(false)

func UpdateDescriptor(Box : Inventory_Box) -> void:

	if (WorkshopDescriptor != null):
		WorkshopDescriptor.SetWorkShopData(Box, HasUpgradeBuff, CurrentShip.Cpt)

func CloseDescriptor() -> void:
	#var descriptors = get_tree().get_nodes_in_group("ItemDescriptor")
	if (WorkshopDescriptor != null):
		WorkshopDescriptor.queue_free()
	ShipStats.get_parent().visible = true

func RemoveItem(Box : Inventory_Box) -> void:
	var Cost = Box.GetContainedItem().Cost
	var It = Box.GetContainedItem()
	Map.GetInstance().GetScreenUi().TownUi.CoinsReceived(roundi(Cost / 1000.0))
	var PLWallet = World.GetInstance().PlayerWallet
	PLWallet.AddFunds(Cost)
	PopUpManager.GetInstance().DoFadeNotif("{0} removed from {1}'s ship")
	CurrentShip.Cpt.GetCharacterInventory().RemoveItem(It)
	RefreshInventory()
	CloseDescriptor()
	for g in WorkShopMerch:
		if (g.It.IsSame(It)):
			g.Amm += 1
			return
	
	var NewMerch = Merchandise.new()
	NewMerch.It = It
	NewMerch.Amm = 1
	WorkShopMerch.append(NewMerch)

func AddItem(Box : Inventory_Box) -> void:
	var Type = GetTypeOfBox(Box)
	
	var c1 = Control.new()
	c1.custom_minimum_size.y = 200
	ItemParent.add_child(c1)
	c1.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var Amm : int = 0
	for g in WorkShopMerch:
		if (g.Amm == 0):
			continue
		var It = g.It as ShipPart
		if (Type == It.PartType):
			var B = WorkshopItemUI.instantiate() as WorkShopItem
			B.Init(g)
			B.OnItemBought.connect(ItemToAddSelected.bind(g))
			ItemParent.add_child(B)
			Amm += 1
	
	if (Amm == 0):
		PopUpManager.GetInstance().DoFadeNotif("No available parts for slot found")
		for g in ItemParent.get_children():
			g.queue_free()
		return
	PopUpManager.GetInstance().DoFadeNotif("{0} combatible parts found".format([Amm]))
	ItemCat.visible = true
	var c2 = Control.new()
	c2.custom_minimum_size.y = 200
	ItemParent.add_child(c2)
	c2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
func ItemToAddSelected(M : Merchandise) -> void:
	var OriginalItem : ShipPart = M.It

	
	var OriginalCap = CurrentShip.Cpt
	var OriginalInv = OriginalCap._CharInv


	var Cost = M.It.Cost

	var PLWallet = World.GetInstance().PlayerWallet
	
	if (PLWallet.Funds < Cost):
		PopUpManager.GetInstance().DoFadeNotif("Cant pay for item")
		return
	
	
	var NewCap = OriginalCap.duplicate(true) as Captain
	var NewInv = OriginalInv.duplicate(4) as CharacterInventory
	NewCap._CharInv = NewInv
	var NewStats : Array[ShipStat]
	for g :ShipStat in OriginalCap.CaptainStats:
		NewStats.append(g.duplicate(true))
	NewCap.CaptainStats = NewStats
	NewInv._InventoryContents = OriginalInv._InventoryContents.duplicate()
	#NewInv._CardInventory = OriginalInv._CardInventory.duplicate()

	NewInv.AddItem(OriginalItem)
	NewCap.OnShipPartAddedToInventory(OriginalItem)
	
	var StatC = StatComp.instantiate() as StatComperator
	StatC.SetCaptainsToCompare(OriginalCap, NewCap)
	add_child(StatC)
	
	var Resault = await StatC.TradeFinished
	StatC.queue_free()
	
	if (!Resault):
		
		return
			
	
	
	M.Amm -= 1
	
	PLWallet.AddFunds(-Cost)
	Map.GetInstance().GetScreenUi().TownUi.DropCoins(roundi(Cost / 100.0))
	
	ItemCat.visible = false
	for g in ItemParent.get_children():
		g.queue_free()
	CurrentShip.Cpt.GetCharacterInventory().AddItem(M.It)
	PopUpManager.GetInstance().DoFadeNotif("{0} Added".format([M.It.ItemName]))
	RefreshInventory()
	CloseDescriptor()
	

func UpgradeItem(Box : Inventory_Box) -> void:
	
	var OriginalItem : ShipPart = Box.GetContainedItem()
	var UpgradedItem : ShipPart = OriginalItem.UpgradeVersion
	
	var OriginalCap = CurrentShip.Cpt
	var OriginalInv = OriginalCap._CharInv
	
	if (OriginalInv._ItemBeingUpgraded != null):
		PopUpManager.GetInstance().DoFadeNotif("Ship is already upgrading a part")
		#print("Ship is already upgrading a part. Wait for it to finish first.")
		return
	if (OriginalInv._ItemBeingEquipped != null):
		PopUpManager.GetInstance().DoFadeNotif("Ship having a part equipped to it")
		#print("Ship is already upgrading a part. Wait for it to finish first.")
		return

	var Cost = UpgradedItem.Cost
	if (HasUpgradeBuff):
		Cost *= 0.75
	var PLWallet = World.GetInstance().PlayerWallet
	if (PLWallet.Funds < Cost):
		PopUpManager.GetInstance().DoFadeNotif("Cant pay for upgrade")
		return
	
	
	var NewCap = OriginalCap.duplicate(true) as Captain
	var NewInv = OriginalInv.duplicate(4) as CharacterInventory
	NewCap._CharInv = NewInv
	var NewStats : Array[ShipStat]
	for g :ShipStat in OriginalCap.CaptainStats:
		NewStats.append(g.duplicate(true))
	NewCap.CaptainStats = NewStats
	NewInv._InventoryContents = OriginalInv._InventoryContents.duplicate()
	#NewInv._CardInventory = OriginalInv._CardInventory.duplicate()
	
	NewInv.RemoveItem(OriginalItem)
	NewInv.AddItem(UpgradedItem)

	NewCap.OnShipPartRemovedFromInventory(OriginalItem)
	NewCap.OnShipPartAddedToInventory(UpgradedItem)
	
	var StatC = StatComp.instantiate() as StatComperator
	StatC.SetCaptainsToCompare(OriginalCap, NewCap)
	add_child(StatC)
	
	var Resault = await StatC.TradeFinished
	
	StatC.queue_free()
	
	if (!Resault):
		
		return
	
	PLWallet.AddFunds(-Cost)
	Map.GetInstance().GetScreenUi().TownUi.DropCoins(roundi(Cost / 100))
	
	PopUpManager.GetInstance().DoFadeNotif("{0} upgrade initiated".format([OriginalItem.ItemName]))
	
	var Inv = CurrentShip.Cpt.GetCharacterInventory()
	
	var box = Inv.GetBoxContainingItem(Box._ContainedItem)
	
	InventoryManager.GetInstance().ItemUpdgrade(box, Inv)
	UpdateDescriptor(Box)

func _on_button_pressed() -> void:
	WorkshopClosed.emit()
	queue_free()


func _on_cancel_button_pressed() -> void:
	ItemCat.visible = false
	for g in ItemParent.get_children():
		g.queue_free()

func _on_sell_pressed() -> void:
	if (CurrentShip is PlayerShip):
		PopUpManager.GetInstance().DoFadeNotif("Flagship can't be sold")
		return
	var s = PopUpManager.GetInstance().DoConfirm("Sell ship?", "Yes", null)
	s.Sign.connect(SellConfirmed)

func SellConfirmed(t : bool) -> void:
	if (!t):
		return
	var PLWallet = World.GetInstance().PlayerWallet
	PLWallet.AddFunds(CurrentShip.GetValue())
	ShipSold.emit(CurrentShip)
	AvailableShips.erase(CurrentShip)
	RefreshCaptains()
	


func _on_stats_button_pressed() -> void:
	ShipStats.ShowStats()


func _on_deck_button_pressed() -> void:
	ShipStats.ShowDeck()

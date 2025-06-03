extends Control

class_name WorkShop

@export var ShipButtonsParent : Control

@export var EngineInventoryBoxParent : GridContainer
@export var SensorInventoryBoxParent : GridContainer
@export var FuelTankInventoryBoxParent : GridContainer
@export var WeaponInventoryBoxParent : GridContainer
@export var ShieldInventoryBoxParent : GridContainer
@export var DescriptorPlace : Control

@export var ItemDescriptorScene : PackedScene
@export var InventoryBoxScene : PackedScene
@export var StatComp : PackedScene

var CurrentShip : MapShip

signal WorkshopClosed

func Init(Ships : Array[MapShip]) -> void:
	for g in Ships:
		var b = Button.new()
		ShipButtonsParent.add_child(b)
		b.text = g.Cpt.CaptainName
		b.pressed.connect(OnShipSelected.bind(g))
	
	OnShipSelected(Ships[0])

func OnShipSelected(Ship : MapShip) -> void:
	if (Ship == CurrentShip):
		return
	
	var descriptors = get_tree().get_nodes_in_group("ItemDescriptor")
	if (descriptors.size() > 0):
		var desc = descriptors[0] as ItemDescriptor
		DescriptorPlace.remove_child(desc)
		desc.queue_free()
	
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
	
	$PanelContainer/VBoxContainer/HBoxContainer/TextureRect.texture = Ship.Cpt.ShipIcon
	
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
		EngineInventoryBoxParent.columns = min(2, CharEngineSpace)
	
	for g in CharSensorSpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		SensorInventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
		Box.Enable()
		SensorInventoryBoxParent.columns = min(2, CharSensorSpace)
	
	for g in CharFuelTankSpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		FuelTankInventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
		Box.Enable()
		FuelTankInventoryBoxParent.columns = min(2, CharFuelTankSpace)
	
	for g in CharShieldSpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		ShieldInventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
		Box.Enable()
		ShieldInventoryBoxParent.columns = min(2, CharShieldSpace)
	
	for g in CharWeaponSpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		WeaponInventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
		Box.Enable()
		WeaponInventoryBoxParent.columns = min(2, CharWeaponSpace)
	
	var inv = Cha.GetCharacterInventory()
	
	for g in inv.GetInventoryContents():
		if (g is ShipPart):
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
	
	var descriptors = get_tree().get_nodes_in_group("ItemDescriptor")
	if (descriptors.size() > 0):
		var desc = descriptors[0] as ItemDescriptor
		DescriptorPlace.remove_child(desc)
		desc.queue_free()
		if (desc.DescribedContainer == Box):
			return
	
			
	var Descriptor = ItemDescriptorScene.instantiate() as ItemDescriptor
	Descriptor.DescribedContainer = Box
	if (Box.IsEmpty()):
		Descriptor.SetEmptyShopData(GetTypeOfBox(Box))
	else:
		var HasUp = false
		if (CurrentShip.Cpt.CurrentPort != ""):

			HasUp = CurrentShip.CurrentPort.HasUpgrade()
		Descriptor.SetData(Box, HasUp, true, false, true, true, false)
		#Descriptor.connect("ItemUsed", UseItem)
		Descriptor.connect("ItemUpgraded", UpgradeItem)
		
		#Descriptor.connect("ItemDropped", OwnerInventory.RemoveItemFromBox)
		#Descriptor.connect("ItemTransf", ItemTranfer)
	DescriptorPlace.add_child(Descriptor)
	Descriptor.set_physics_process(false)
	
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
	#if (OriginalCap.CurrentPort == ""):
		#PopUpManager.GetInstance().DoFadeNotif("Ship needs to be docked to upgrade")
		#return
	
	var NewCap = OriginalCap.duplicate(true) as Captain
	var NewInv = OriginalInv.duplicate(4) as CharacterInventory
	NewCap._CharInv = NewInv
	var NewStats : Array[ShipStat]
	for g in OriginalCap.CaptainStats:
		NewStats.append(g.duplicate())
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
	
	PopUpManager.GetInstance().DoFadeNotif("{0} upgrade initiated".format([OriginalItem.ItemName]))
	
	var Inv = CurrentShip.Cpt.GetCharacterInventory()
	
	var box = Inv.GetBoxContainingItem(Box._ContainedItem)
	
	InventoryManager.GetInstance().ItemUpdgrade(box, Inv)
	

func _on_button_pressed() -> void:
	WorkshopClosed.emit()
	queue_free()

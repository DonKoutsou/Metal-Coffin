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

var CurrentShip : MapShip

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
	
	$PanelContainer/VBoxContainer/HBoxContainer/PanelContainer2/HBoxContainer/TextureRect.texture = Ship.Cpt.ShipIcon
	
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
	
	for g in CharSensorSpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		SensorInventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
	
	for g in CharFuelTankSpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		FuelTankInventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
	
	for g in CharShieldSpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		ShieldInventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
	
	for g in CharWeaponSpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		WeaponInventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
	
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

func ItemSelected(Box : Inventory_Box) -> void:
	var descriptors = get_tree().get_nodes_in_group("ItemDescriptor")
	if (descriptors.size() > 0):
		var desc = descriptors[0] as ItemDescriptor
		DescriptorPlace.remove_child(desc)
		desc.queue_free()
		if (desc.DescribedContainer == Box):
			return
			
			
	var Descriptor = ItemDescriptorScene.instantiate() as ItemDescriptor
	
	

	var HasUp = false
	if (CurrentShip.Cpt.CurrentPort != ""):

		HasUp = CurrentShip.CurrentPort.HasUpgrade()
	Descriptor.SetWorkShopData(Box, HasUp, CurrentShip.Cpt)
	#Descriptor.connect("ItemUsed", UseItem)
	Descriptor.connect("ItemUpgraded", UpgradeItem)
	#Descriptor.connect("ItemDropped", OwnerInventory.RemoveItemFromBox)
	#Descriptor.connect("ItemTransf", ItemTranfer)
	DescriptorPlace.add_child(Descriptor)
	Descriptor.set_physics_process(false)
func UpgradeItem(Box : Inventory_Box) -> void:
	var Inv = CurrentShip.Cpt.GetCharacterInventory()
	
	var box = Inv.GetBoxContainingItem(Box._ContainedItem)
	
	InventoryManager.GetInstance().ItemUpdgrade(box, Inv)

extends Control

class_name TeamEquipmentSetup

@export var InventoryBoxScene : PackedScene
@export var EngineInventoryBoxParent : GridContainer
@export var SensorInventoryBoxParent : GridContainer
@export var FuelTankInventoryBoxParent : GridContainer
@export var WeaponInventoryBoxParent : GridContainer
@export var ShieldInventoryBoxParent : GridContainer
@export var InventoryBoxParent : GridContainer
@export var DescriptorPlace : Control
@export var DeckUI : ShipDeckViz
@export var ItemDescriptorScene : PackedScene
@export var PlayerCaptainLocation : Control
@export var EnemyCaptainLocation : Control
@export var Equipment : Array[Item]
@export var CaptainName : Label
@export var CaptainB : PackedScene
@export_group("ItemCatalogue")
@export var ItemCatalogue : Control
@export var ItemParent : Control

var CurrentCpt : Captain
var CurrentDescriptor : ItemDescriptor

#func _ready() -> void:
	#var b = CaptainB.instantiate() as CaptainButton
	#var Cpt = load("res://Resources/Captains/PlayerCaptains/Craden.tres") as Captain
	#b.SetCpt(Cpt)
	#b.OnShipSelected.connect(OnCaptainSelected.bind(Cpt))
	#PlayerCaptainLocation.add_child(b)
	#OnCaptainSelected()

func Clear() -> void:
	for g in PlayerCaptainLocation.get_children():
		g.queue_free()
	for g in EnemyCaptainLocation.get_children():
		g.queue_free()
	
	var descriptors = get_tree().get_nodes_in_group("ItemDescriptor")
	if (descriptors.size() > 0):
		var desc = descriptors[0] as ItemDescriptor
		DescriptorPlace.remove_child(desc)
		desc.queue_free()
	
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
	for g in InventoryBoxParent.get_children():
		g.free()
	
	DeckUI.Clear()
	CurrentCpt = null

func Init(PlayerCaptains : Array[Captain], EnemyCaptains : Array[Captain]) -> void:

	for g in PlayerCaptains:
		var b = CaptainB.instantiate() as CaptainButton
		b.SetCpt(g)
		b.OnShipSelected.connect(OnCaptainSelected.bind(g))
		PlayerCaptainLocation.add_child(b)
		
	for g in EnemyCaptains:
		var b = CaptainB.instantiate() as CaptainButton
		b.SetCpt(g)
		b.OnShipSelected.connect(OnCaptainSelected.bind(g))
		EnemyCaptainLocation.add_child(b)
	
func OnCaptainSelected(Cpt : Captain) -> void:
	if (Cpt == CurrentCpt):
		return
	
	CaptainName.text = Cpt.CaptainName
	var descriptors = get_tree().get_nodes_in_group("ItemDescriptor")
	if (descriptors.size() > 0):
		var desc = descriptors[0] as ItemDescriptor
		DescriptorPlace.remove_child(desc)
		DeckUI.get_parent().visible = true
		desc.queue_free()
	
	CurrentCpt = Cpt
	
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
	for g in InventoryBoxParent.get_children():
		g.free()
	#$PanelContainer/VBoxContainer/HBoxContainer/TextureRect.texture = Cpt.ShipIcon
	
	var CharEngineSpace = Cpt._GetStat(STAT_CONST.STATS.ENGINES_SLOTS).StatBase
	var CharSensorSpace = Cpt._GetStat(STAT_CONST.STATS.SENSOR_SLOTS).StatBase
	var CharFuelTankSpace = Cpt._GetStat(STAT_CONST.STATS.FUEL_TANK_SLOTS).StatBase
	var CharShieldSpace = Cpt._GetStat(STAT_CONST.STATS.SHIELD_SLOTS).StatBase
	var CharWeaponSpace = Cpt._GetStat(STAT_CONST.STATS.WEAPON_SLOTS).StatBase
	var CharInventorySpace = Cpt._GetStat(STAT_CONST.STATS.INVENTORY_SPACE).StatBase
	
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
	
	for g in CharInventorySpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		InventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
		Box.Enable()
		InventoryBoxParent.columns = min(2, CharInventorySpace)
	
	var itms = Cpt.StartingItems
	
	for g in itms:
		if (g is ShipPart):
			for box : Inventory_Box in GetBoxParentForType(g.PartType).get_children():
				if box.IsEmpty():
					box.RegisterItem(g)
					box.UpdateAmm(1)
					break
		else:
			for box : Inventory_Box in InventoryBoxParent.get_children():
				if box.IsEmpty():
					box.RegisterItem(g)
					box.UpdateAmm(1)
					break
				else : if (box.GetContainedItem() == g):
					box.UpdateAmm(1)
					break
	
	DeckUI.SetDeck2(Cpt)

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
	else:
		BoxParent = InventoryBoxParent
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
	else: 
		Type = ShipPart.ShipPartType.INVENTORY
	return Type

func ItemSelected(Box : Inventory_Box) -> void:
	if (CurrentDescriptor != null):
		#var desc = descriptors[0] as ItemDescriptor
		DescriptorPlace.remove_child(CurrentDescriptor)
		CurrentDescriptor.queue_free()
		DeckUI.get_parent().visible = true
		if (CurrentDescriptor.DescribedContainer == Box):
			return
	
	CurrentDescriptor = ItemDescriptorScene.instantiate() as ItemDescriptor
	CurrentDescriptor.DescribedContainer = Box
	if (Box.IsEmpty()):
		CurrentDescriptor.SetEmptyShopData(GetTypeOfBox(Box))
	else:
		CurrentDescriptor.SetData(Box, true, true, false, true, true, true)
	
	CurrentDescriptor.ItemAdd.connect(AddItem)
	CurrentDescriptor.ItemUpgraded.connect(UpgradeItem)
	CurrentDescriptor.ItemRemove.connect(RemoveItem)
	CurrentDescriptor.ItemIncrease.connect(IncreaseItem)
	
	DescriptorPlace.add_child(CurrentDescriptor)
	DeckUI.get_parent().visible = false
	CurrentDescriptor.set_physics_process(false)
	CurrentDescriptor.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func UpdateDescriptor(Box : Inventory_Box) -> void:
	if (CurrentDescriptor != null):
		CurrentDescriptor.SetData(Box, true, true, false, true, true, true)

func UpgradeItem(Box : Inventory_Box) -> void:
	var OriginalItem = Box.GetContainedItem() as ShipPart
	CurrentCpt.StartingItems.erase(OriginalItem)
	var UpgradedItem = OriginalItem.UpgradeVersion
	CurrentCpt.StartingItems.append(UpgradedItem)
	Box.RegisterItem(UpgradedItem)
	#Box.UpdateAmm(1)
	DeckUI.SetDeck2(CurrentCpt)
	UpdateDescriptor(Box)
	PopUpManager.GetInstance().DoFadeNotif("{0} Upgraded".format([OriginalItem.ItemName]))

var SelectedContainer : Inventory_Box
func AddItem(Box : Inventory_Box) -> void:
	ItemCatalogue.visible = true
	SelectedContainer = Box
	
	var Type = GetTypeOfBox(Box)
	
	var ItemCatalogue : Array[Item]
	
	for g in Equipment:
		if (g is ShipPart):
			if (Type == g.PartType):
				ItemCatalogue.append(g)
		else: if (Type == ShipPart.ShipPartType.INVENTORY):
			ItemCatalogue.append(g)
	
	for g in ItemCatalogue:
		var B = InventoryBoxScene.instantiate() as Inventory_Box
		B.RegisterItem(g)
		B.UpdateAmm(1)
		ItemParent.add_child(B)
		B.ItemSelected.connect(OnItemSelected)
	

func IncreaseItem(Box : Inventory_Box) -> void:
	PopUpManager.GetInstance().DoFadeNotif("{0} Added".format([Box.GetContainedItem().ItemName]))
	Box.UpdateAmm(1)
	CurrentCpt.StartingItems.append(Box.GetContainedItem())
	DeckUI.SetDeck2(CurrentCpt)
	

func OnItemSelected(Box : Inventory_Box) -> void:
	ItemCatalogue.visible = false
	for g in ItemParent.get_children():
		g.queue_free()
	CurrentCpt.StartingItems.append(Box.GetContainedItem())
	SelectedContainer.RegisterItem(Box.GetContainedItem())
	SelectedContainer.UpdateAmm(1)
	DeckUI.SetDeck2(CurrentCpt)
	UpdateDescriptor(SelectedContainer)
	PopUpManager.GetInstance().DoFadeNotif("{0} Added".format([Box.GetContainedItem().ItemName]))

func RemoveItem(Box : Inventory_Box) -> void:
	PopUpManager.GetInstance().DoFadeNotif("{0} Removed".format([Box.GetContainedItem().ItemName]))
	var OriginalItem = Box.GetContainedItem()
	CurrentCpt.StartingItems.erase(OriginalItem)
	Box.UpdateAmmNoDissable(-1)
	DeckUI.SetDeck2(CurrentCpt)
	if (Box.IsEmpty()):
		ItemSelected(Box)

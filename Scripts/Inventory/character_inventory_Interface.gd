extends VBoxContainer

class_name CharacterInventoryInterface

@export_group("Nodes")
@export var InventoryBoxScene : PackedScene
@export var EngineInventoryBoxParent : Control
@export var SensorInventoryBoxParent : Control
@export var FuelTankInventoryBoxParent : Control
@export var WeaponInventoryBoxParent : Control
@export var ShieldInventoryBoxParent : Control
@export var InventoryBoxParent : Control

var KeepBoxesActive : bool = false
signal BoxSelected(Box : Inventory_Box_Res)

func InitialiseInventory(cpt : Captain) -> void:
	for g in InventoryBoxParent.get_children():
		g.queue_free()
	for g in EngineInventoryBoxParent.get_children():
		g.queue_free()
	for g in SensorInventoryBoxParent.get_children():
		g.queue_free()
	for g in FuelTankInventoryBoxParent.get_children():
		g.queue_free()
	for g in ShieldInventoryBoxParent.get_children():
		g.queue_free()
	for g in WeaponInventoryBoxParent.get_children():
		g.queue_free()
	
	var inv = cpt.GetCharacterInventory()
	
	if (inv == null):
		return
	
	for g in inv.boxes:
		var par = GetBoxParentForType(g)
		for box : Inventory_Box_Res in inv.boxes[g]:
			var Box = InventoryBoxScene.instantiate() as Inventory_Box
			if (KeepBoxesActive):
				Box.allowDissable = false
			Box.Initialise(box)
			par.add_child(Box)
			Box.connect("ItemSelected", ItemSelected)



func InitStartingInventory(Cha : Captain) -> void:
	var CharInvSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.INVENTORY_SPACE)
	var CharEngineSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.ENGINES_SLOTS)
	var CharSensorSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.SENSOR_SLOTS)
	var CharFuelTankSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK_SLOTS)
	var CharShieldSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.SHIELD_SLOTS)
	var CharWeaponSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.WEAPON_SLOTS)

	for g in CharInvSpace:
		var par = GetBoxParentForType(ShipPart.ShipPartType.INVENTORY)
		var boxRes = Inventory_Box_Res.new()
		boxRes.Initialise(Cha.GetCharacterInventory())
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		if (KeepBoxesActive):
			Box.allowDissable = false
		Box.Initialise(boxRes)
		par.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
	
	for g in CharEngineSpace:
		var par = GetBoxParentForType(ShipPart.ShipPartType.ENGINE)
		var boxRes = Inventory_Box_Res.new()
		boxRes.Initialise(Cha.GetCharacterInventory())
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		if (KeepBoxesActive):
			Box.allowDissable = false
		Box.Initialise(boxRes)
		par.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
	
	for g in CharSensorSpace:
		var par = GetBoxParentForType(ShipPart.ShipPartType.SENSOR)
		var boxRes = Inventory_Box_Res.new()
		boxRes.Initialise(Cha.GetCharacterInventory())
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		if (KeepBoxesActive):
			Box.allowDissable = false
		Box.Initialise(boxRes)
		par.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
	
	for g in CharFuelTankSpace:
		var par = GetBoxParentForType(ShipPart.ShipPartType.FUEL_TANK)
		var boxRes = Inventory_Box_Res.new()
		boxRes.Initialise(Cha.GetCharacterInventory())
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		if (KeepBoxesActive):
			Box.allowDissable = false
		Box.Initialise(boxRes)
		par.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)

		#FuelTankInventoryBoxParent.columns = min(2, CharFuelTankSpace)
	
	for g in CharShieldSpace:
		var par = GetBoxParentForType(ShipPart.ShipPartType.SHIELD)
		var boxRes = Inventory_Box_Res.new()
		boxRes.Initialise(Cha.GetCharacterInventory())
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		if (KeepBoxesActive):
			Box.allowDissable = false
		Box.Initialise(boxRes)
		par.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)

		#ShieldInventoryBoxParent.columns = min(2, CharShieldSpace)
	
	for g in CharWeaponSpace:
		var par = GetBoxParentForType(ShipPart.ShipPartType.WEAPON)
		var boxRes = Inventory_Box_Res.new()
		boxRes.Initialise(Cha.GetCharacterInventory())
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		if (KeepBoxesActive):
			Box.allowDissable = false
		Box.Initialise(boxRes)
		par.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
	
	#for It in Cha.StartingItems:
		#var boxeList = boxes[It.PartType]
#
		#var Empty : Inventory_Box_Res = null
		#for g : Inventory_Box_Res in boxeList:
			#if (g.IsEmpty()):
				#if (Empty == null):
					#Empty = g
				#continue
			#if (g.GetContainedItemName() == It.ItemName and g.HasSpace()):
				#g.UpdateAmm(1)
				#_InventoryContents[It] += 1
#
				#break
		##try to find empty box
		#if (Empty != null):
			#Empty.RegisterItem(It)
			#Empty.UpdateAmm(1)
			#if (_InventoryContents.has(It)):
				#_InventoryContents[It] += 1
			#else:
				#_InventoryContents[It] = 1
#
			#continue

func SetBoxedSelectable() -> void:
	for g : Inventory_Box in InventoryBoxParent.get_children():
		g.Enable()
	for g : Inventory_Box in EngineInventoryBoxParent.get_children():
		g.Enable()
	for g : Inventory_Box in SensorInventoryBoxParent.get_children():
		g.Enable()
	for g : Inventory_Box in FuelTankInventoryBoxParent.get_children():
		g.Enable()
	for g : Inventory_Box in ShieldInventoryBoxParent.get_children():
		g.Enable()
	for g : Inventory_Box in WeaponInventoryBoxParent.get_children():
		g.Enable()

func ItemSelected(Box : Inventory_Box_Res) -> void:
	BoxSelected.emit(Box)

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
	else : if (PartType == ShipPart.ShipPartType.INVENTORY):
		BoxParent = InventoryBoxParent
	return BoxParent

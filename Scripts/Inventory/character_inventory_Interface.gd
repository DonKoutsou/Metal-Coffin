extends VBoxContainer

class_name CharacterInventoryInterface

@export_group("Nodes")
@export var InventoryBoxScene : PackedScene
@export var EngineInventoryBoxParent : VBoxContainer
@export var SensorInventoryBoxParent : VBoxContainer
@export var FuelTankInventoryBoxParent : VBoxContainer
@export var WeaponInventoryBoxParent : VBoxContainer
@export var ShieldInventoryBoxParent : VBoxContainer
@export var InventoryBoxParent : VBoxContainer

signal BoxSelected(Box : Inventory_Box_Res)

func InitialiseInventory(inv : CharacterInventory) -> void:
	if (inv == null):
		return
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
		
	for g in inv.boxes:
		var par = GetBoxParentForType(g)
		for box : Inventory_Box_Res in inv.boxes[g]:
			var Box = InventoryBoxScene.instantiate() as Inventory_Box
			Box.Initialise(box)
			par.add_child(Box)
			Box.connect("ItemSelected", ItemSelected)
	
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

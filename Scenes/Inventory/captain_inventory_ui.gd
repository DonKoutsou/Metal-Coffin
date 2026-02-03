extends HBoxContainer

@export var InventoryBoxScene : PackedScene
@export var EngineInventoryBoxParent : VBoxContainer
@export var SensorInventoryBoxParent : VBoxContainer
@export var FuelTankInventoryBoxParent : VBoxContainer
@export var WeaponInventoryBoxParent : VBoxContainer
@export var ShieldInventoryBoxParent : VBoxContainer
@export var InventoryBoxParent : VBoxContainer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func InitialiseInventory(Cha : Captain) -> void:
	var CharInvSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.INVENTORY_SPACE)
	var CharEngineSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.ENGINES_SLOTS)
	var CharSensorSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.SENSOR_SLOTS)
	var CharFuelTankSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK_SLOTS)
	var CharShieldSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.SHIELD_SLOTS)
	var CharWeaponSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.WEAPON_SLOTS)
	
	#var CharName = Cha.GetCaptainName()
	#var Inv = Cha.GetCharacterInventory()
	#for g in CharInvSpace:
		#var Box = InventoryBoxScene.instantiate() as Inventory_Box
		#Box.Initialise(Inv)
		#InventoryBoxParent.add_child(Box)
		#Box.connect("ItemSelected", ItemSelected)
		##InventoryBoxParent.columns = min(2, CharInvSpace)
	#
	#for g in CharEngineSpace:
		#var Box = InventoryBoxScene.instantiate() as Inventory_Box
		#Box.Initialise(Inv)
		#EngineInventoryBoxParent.add_child(Box)
		#Box.connect("ItemSelected", ItemSelected)
		##EngineInventoryBoxParent.columns = min(2, CharEngineSpace)
	#
	#for g in CharSensorSpace:
		#var Box = InventoryBoxScene.instantiate() as Inventory_Box
		#Box.Initialise(Inv)
		#SensorInventoryBoxParent.add_child(Box)
		#Box.connect("ItemSelected", ItemSelected)
		##SensorInventoryBoxParent.columns = min(2, CharSensorSpace)
	#
	#for g in CharFuelTankSpace:
		#var Box = InventoryBoxScene.instantiate() as Inventory_Box
		#Box.Initialise(Inv)
		#FuelTankInventoryBoxParent.add_child(Box)
		#Box.connect("ItemSelected", ItemSelected)
		##FuelTankInventoryBoxParent.columns = min(2, CharFuelTankSpace)
	#
	#for g in CharShieldSpace:
		#var Box = InventoryBoxScene.instantiate() as Inventory_Box
		#Box.Initialise(Inv)
		#ShieldInventoryBoxParent.add_child(Box)
		#Box.connect("ItemSelected", ItemSelected)
		##ShieldInventoryBoxParent.columns = min(2, CharShieldSpace)
	#
	#for g in CharWeaponSpace:
		#var Box = InventoryBoxScene.instantiate() as Inventory_Box
		#Box.Initialise(Inv)
		#WeaponInventoryBoxParent.add_child(Box)
		#Box.connect("ItemSelected", ItemSelected)
		#WeaponInventoryBoxParent.columns = min(2, CharWeaponSpace)

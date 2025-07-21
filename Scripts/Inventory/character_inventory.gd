extends PanelContainer

class_name CharacterInventory

@export_group("Nodes")
@export var InventoryBoxScene : PackedScene
@export var EngineInventoryBoxParent : VBoxContainer
@export var SensorInventoryBoxParent : VBoxContainer
@export var FuelTankInventoryBoxParent : VBoxContainer
@export var WeaponInventoryBoxParent : VBoxContainer
@export var ShieldInventoryBoxParent : VBoxContainer
@export var InventoryBoxParent : VBoxContainer
@export var CaptainNameLabel : LineEdit

signal InventoryUpdated
signal OnItemAdded(it : Item)
signal OnItemRemoved(it : Item)
signal OnShipPartAdded(it : ShipPart)
signal OnShipPartRemoved(it : ShipPart)
signal ItemPlecementFailed(it : Item)
signal BoxSelected(Box : Inventory_Box, OwnerInventory : CharacterInventory)
signal ItemUpgrade(Box : Inventory_Box, OwnerInventory : CharacterInventory)
signal ItemTransf(Box : Inventory_Box, OwnerInventory : CharacterInventory)
signal OnCharacterInspectionPressed
signal OnCharacterDeckInspectionPressed

var _InventoryContents : Dictionary[Item, int]
signal CharNameChanged(NewName : String)
#var _CardInventory : Dictionary
#var _CardAmmo : Dictionary

var SimPaused : bool = false
#var SimSpeed : int = 1
var _ItemBeingUpgraded : Inventory_Box
var _UpgradeTime : float
var _ItemBeingEquipped : ShipPart
var _EquipTime : float


func _ready() -> void:

	InventoryBoxParent.get_parent().get_parent().get_parent().visible = false
	#MissileDockEventH.connect("MissileLaunched", RemoveItem)
	set_physics_process(_ItemBeingUpgraded != null)

func GetCards() -> Array[CardStats]:
	var CardsInInventory : Array[CardStats]
	for g : Item in _InventoryContents:
		var Amm = _InventoryContents[g]
		if (g is AmmoItem and !HasWeapon(g.WType)):
			continue
		if (g is MissileItem and !HasWeapon(CardStats.WeaponType.ML)):
			continue
		for A in Amm:
			for z in g.CardProviding:
				var C = z.duplicate() as CardStats
				C.Tier = g.Tier
				CardsInInventory.append(C)

	return CardsInInventory

func GetCardDictionary() -> Dictionary[CardStats, int]:
	var c : Dictionary[CardStats, int]
	for g in _InventoryContents:
		for v in _InventoryContents[g]:
			if (g is AmmoItem and !HasWeapon(g.WType)):
				continue
			if (g is MissileItem and !HasWeapon(CardStats.WeaponType.ML)):
				continue
			for z in g.CardProviding:
				var C = z.duplicate() as CardStats
				C.Tier = g.Tier
				
				var Added = false
				
				for Ca : CardStats in c.keys():
					if (Ca.IsSame(C)):
						c[Ca] += 1
						Added = true
						break
				if (!Added):
					c[C] = 1
	return c
#func GetCardAmmo() -> Dictionary:
	#return _CardAmmo.duplicate()

func HasWeapon(WType : CardStats.WeaponType) -> bool:
	for g : Item in _InventoryContents.keys():
		if (g is WeaponShipPart):
			if (g.WType == WType):
				return true
	return false

func HasItem(It : Item) -> bool:
	for g in _InventoryContents.keys():
		var it = g as Item
		if (it.resource_path == It.resource_path):
			return true
	return false

func GetInventoryContents() -> Dictionary[Item, int]:
	return _InventoryContents

func InitialiseInventory(Cha : Captain) -> void:
	CharNameChanged.connect(Cha.OnCharacterNameChanged)
	Cha.OnNameChanged.connect(CharacterNameChange)
	
	var CharInvSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.INVENTORY_SPACE)
	var CharEngineSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.ENGINES_SLOTS)
	var CharSensorSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.SENSOR_SLOTS)
	var CharFuelTankSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK_SLOTS)
	var CharShieldSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.SHIELD_SLOTS)
	var CharWeaponSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.WEAPON_SLOTS)
	
	var CharName = Cha.GetCaptainName()
	for g in CharInvSpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		Box.Initialise(self)
		InventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
		#InventoryBoxParent.columns = min(2, CharInvSpace)
	
	for g in CharEngineSpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		Box.Initialise(self)
		EngineInventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
		#EngineInventoryBoxParent.columns = min(2, CharEngineSpace)
	
	for g in CharSensorSpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		Box.Initialise(self)
		SensorInventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
		#SensorInventoryBoxParent.columns = min(2, CharSensorSpace)
	
	for g in CharFuelTankSpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		Box.Initialise(self)
		FuelTankInventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
		#FuelTankInventoryBoxParent.columns = min(2, CharFuelTankSpace)
	
	for g in CharShieldSpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		Box.Initialise(self)
		ShieldInventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
		#ShieldInventoryBoxParent.columns = min(2, CharShieldSpace)
	
	for g in CharWeaponSpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		Box.Initialise(self)
		WeaponInventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
		#WeaponInventoryBoxParent.columns = min(2, CharWeaponSpace)
		
	CaptainNameLabel.text = CharName

func ItemSelected(Box : Inventory_Box) -> void:
	BoxSelected.emit(Box, self)

func AddItem(It : Item) -> void:
	var boxes
	if (It is ShipPart):
		boxes = GetBoxParentForType(It.PartType).get_children()
	else:
		boxes = InventoryBoxParent.get_children()
	var Empty : Inventory_Box = null

	#try to find matching box for it and if not put it on any empty ones we found
	for g in boxes:
		if (g.IsEmpty()):
			if (Empty == null):
				Empty = g
			continue
		if (g.GetContainedItemName() == It.ItemName and g.HasSpace()):
			g.UpdateAmm(1)
			_InventoryContents[It] += 1

			OnItemAdded.emit(It)
			InventoryUpdated.emit()
			
			return
	#try to find empty box
	if (Empty != null):
		Empty.RegisterItem(It)
		Empty.UpdateAmm(1)
		if (_InventoryContents.has(It)):
			_InventoryContents[It] += 1
		else:
			_InventoryContents[It] = 1

			
		if (It is ShipPart):
			#var BoxParent = GetBoxParentForType(It.PartType)

			OnShipPartAdded.emit(It)
		else:
			var BoxParent = InventoryBoxParent
			if (Empty.get_parent() != BoxParent):
				Empty.get_parent().remove_child(Empty)
				BoxParent.add_child(Empty)
		OnItemAdded.emit(It)
		InventoryUpdated.emit()
		
		return
	ItemPlecementFailed.emit(It)
	return

#func HasItem(It : Item) -> bool:
	#return _InventoryContents.has(It)

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
	
func HasSpaceForItem(It : Item) -> bool:
	var boxes
	if (It is ShipPart):
		boxes = GetBoxParentForType(It.PartType).get_children()
	else:
		boxes = InventoryBoxParent.get_children()
	#try to find matching box for it and if not put it on any empty ones we found
	for g in boxes:
		if (g.IsEmpty()):
			return true
		if (g.GetContainedItemName() == It.ItemName and g.HasSpace()):
			return true
	return false

func GetBoxContainingItem(It : Item) -> Inventory_Box:
	var boxes
	if (It is ShipPart):
		boxes = GetBoxParentForType(It.PartType).get_children()
	else:
		boxes = InventoryBoxParent.get_children()
	
	var Box : Inventory_Box
	
	for g : Inventory_Box in boxes:
		if (g.IsEmpty()):
			continue
		if (g.GetContainedItem().IsSame(It)):
			Box = g
			
	return Box
#called for Item Descriptor once the Drop button is pressed. Signal is connected through Inventory manager when descriptor is created.
func RemoveItemFromBox(Box : Inventory_Box) -> void:
	var It = Box.GetContainedItem()
	
	Box.UpdateAmm(-1)
	_InventoryContents[It] -= 1
	if (_InventoryContents[It] == 0):
		_InventoryContents.erase(It)
	
	if (It is ShipPart):
		OnShipPartRemoved.emit(It)
	OnItemRemoved.emit(It)
	InventoryUpdated.emit()
	
func RemoveItem(It : Item) -> void:
	for g in _GetInventoryBoxes():
		var box = g as Inventory_Box
		if (box.IsEmpty()):
			continue
		if (box.GetContainedItemName() == It.ItemName):
			RemoveItemFromBox(box)
			
			return

func _GetInventoryBoxes() -> Array:
	var Boxes : Array
	Boxes.append_array(EngineInventoryBoxParent.get_children())
	Boxes.append_array(SensorInventoryBoxParent.get_children())
	Boxes.append_array(FuelTankInventoryBoxParent.get_children())
	Boxes.append_array(WeaponInventoryBoxParent.get_children())
	Boxes.append_array(ShieldInventoryBoxParent.get_children())
	Boxes.append_array(InventoryBoxParent.get_children())
	return Boxes

func UpgradeItem(Box : Inventory_Box) -> void:
	
	#else :if (!Player.cu):
		#PopUpManager.GetInstance().DoFadeNotif("Cant upgrade ship in current port.")
		#return
	ItemUpgrade.emit(Box, self)


func TransferItem(Box : Inventory_Box) -> void:
	ItemTransf.emit(Box, self)

func StartUpgrade(Box : Inventory_Box, UpgradeBuff : bool) -> void:
	var Part = Box.GetContainedItem() as ShipPart
	_UpgradeTime = Part.UpgradeTime
	if (UpgradeBuff):
		_UpgradeTime /= 2
	_ItemBeingUpgraded = Box
	set_physics_process(true)

func ReStartUpgrade(Box : Inventory_Box, UpTime : float) -> void:
	#var Part = Box.GetContainedItem() as ShipPart
	_UpgradeTime = UpTime
	_ItemBeingUpgraded = Box
	set_physics_process(true)
	
func _physics_process(delta: float) -> void:
	if (SimPaused):
		return
	_UpgradeTime -= (delta * 10) * SimulationManager.SimSpeed()
	_EquipTime -= (delta * 10) * SimulationManager.SimSpeed()
	#_UpgradeTime -= (delta * 10)
	if (_ItemBeingUpgraded != null and _UpgradeTime <= 0):
		ItemUpgradeFinished()
	
	if (_ItemBeingEquipped != null and _EquipTime <= 0):
		ItemEquipFinished()
	
	set_physics_process(_UpgradeTime > 0 or _EquipTime > 0)

func CancelUpgrade() -> void:
	_ItemBeingUpgraded = null
	set_physics_process(false)

func ItemUpgradeFinished() -> void:
	var Part = _ItemBeingUpgraded.GetContainedItem() as ShipPart
	RemoveItemFromBox(_ItemBeingUpgraded)
	var UpgradedItem = Part.UpgradeVersion.duplicate(true)
	for g in Part.Upgrades.size():
		UpgradedItem.Upgrades[g].CurrentValue = Part.Upgrades[g].CurrentValue
	AddItem(UpgradedItem)
	_ItemBeingUpgraded = null
	PopUpManager.GetInstance().DoFadeNotif("{0}'s {1} has succsfully been upgraded to {2}".format([CaptainNameLabel.text, Part.ItemName, UpgradedItem.ItemName]), null, 8)

func ItemEquipFinished() -> void:
	AddItem(_ItemBeingEquipped)
	_ItemBeingUpgraded = null

func ForceUpgradeItem(Box : Inventory_Box) -> bool:
	var Part = Box.GetContainedItem() as ShipPart
	
	if (Part == null):
		return false
	
	if (Part.UpgradeVersion == null):
		return false
	
	RemoveItemFromBox(Box)
	
	var UpgradedItem = Part.UpgradeVersion.duplicate(true)
	for g in Part.Upgrades.size():
		UpgradedItem.CurrentValue = Part.Upgrades[g].CurrentValue
	AddItem(UpgradedItem)
	
	return true

func GetUpgradeTimeLeft() -> float:
	return _UpgradeTime

func GetItemBeingUpgraded() -> Inventory_Box:
	return _ItemBeingUpgraded


func _on_button_pressed() -> void:
	OnCharacterInspectionPressed.emit()

func _on_deck_pressed() -> void:
	OnCharacterDeckInspectionPressed.emit()

func _on_inventory_vis_toggle_pressed() -> void:
	$VBoxContainer2/VBoxContainer/HBoxContainer2/VBoxContainer/InventoryVisToggle.disabled = true
	var prevc = custom_minimum_size.y
	custom_minimum_size.y = 0
	var Show = !InventoryBoxParent.get_parent().get_parent().get_parent().visible
	InventoryBoxParent.get_parent().get_parent().get_parent().visible = !InventoryBoxParent.get_parent().get_parent().get_parent().visible
	var TargetSize
	if (Show):
		TargetSize = 500
		InventoryBoxParent.get_parent().get_parent().get_parent().visible = !InventoryBoxParent.get_parent().get_parent().get_parent().visible
	else:
		TargetSize = 0
		custom_minimum_size.y = prevc
		
	var Tw = create_tween()
	Tw.set_ease(Tween.EASE_OUT)
	Tw.set_trans(Tween.TRANS_QUAD)
	Tw.tween_property(self, "custom_minimum_size", Vector2(0,TargetSize), 0.5)
	
	await Tw.finished
	if (Show):
		InventoryBoxParent.get_parent().get_parent().get_parent().visible = !InventoryBoxParent.get_parent().get_parent().get_parent().visible

	#if (InventoryBoxParent.get_parent().get_parent().visible):
		#$VBoxContainer2/VBoxContainer/HBoxContainer2/VBoxContainer/InventoryVisToggle.text = "Hide Inventory"
	#else:
		#$VBoxContainer2/VBoxContainer/HBoxContainer2/VBoxContainer/InventoryVisToggle.text = "Show Inventory"
	
	$VBoxContainer2/VBoxContainer/HBoxContainer2/VBoxContainer/InventoryVisToggle.disabled = false

func CharacterNameChange(NewNae : String) -> void:
	if (CaptainNameLabel.text != NewNae):
		CaptainNameLabel.text = NewNae

func _on_character_name_text_changed(NewText : String) -> void:
	CharNameChanged.emit(NewText)

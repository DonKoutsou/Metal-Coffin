extends PanelContainer

class_name CharacterInventory

@export_group("Nodes")
@export var CaptainNameLabel : LineEdit
@export var HideOnStart : bool = true
@export var interface : CharacterInventoryInterface
signal InventoryUpdated
signal OnItemAdded(it : Item)
signal OnItemRemoved(it : Item)
signal OnShipPartAdded(it : ShipPart)
signal OnShipPartRemoved(it : ShipPart)
signal ItemPlecementFailed(it : Item)
signal BoxSelected(Box : Inventory_Box_Res, OwnerInventory : CharacterInventory)
signal ItemUpgrade(Box : Inventory_Box_Res, OwnerInventory : CharacterInventory)
signal ItemTransf(Box : Inventory_Box_Res, OwnerInventory : CharacterInventory)
signal OnCharacterInspectionPressed
signal OnCharacterDeckInspectionPressed
signal OnCharacterInventoryInspectionPressed

var _InventoryContents : Dictionary[Item, int]
var boxes : Dictionary[ShipPart.ShipPartType, Array] = {
	ShipPart.ShipPartType.INVENTORY : [],
	ShipPart.ShipPartType.ENGINE : [],
	ShipPart.ShipPartType.SENSOR : [],
	ShipPart.ShipPartType.FUEL_TANK : [],
	ShipPart.ShipPartType.WEAPON : [],
	ShipPart.ShipPartType.SHIELD : [],
}

signal CharNameChanged(NewName : String)
#var _CardInventory : Dictionary
#var _CardAmmo : Dictionary

var SimPaused : bool = false
#var SimSpeed : int = 1
var _ItemBeingUpgraded : Inventory_Box_Res
var _UpgradeTime : float
var _ItemBeingEquipped : ShipPart
var _EquipLocation : Inventory_Box_Res
var _EquipTime : float

var inventoryOwner : MapShip
#var CurrentPort : MapSpot

func _ready() -> void:
	
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

func GetMissile() -> Array[Item]:
	var Missiles : Array[Item]
	
	for g in _InventoryContents:
		if (g is MissileItem and g.Type == MissileItem.MissileType.BVR):
			for Mis in _InventoryContents[g]:
				Missiles.append(g)
			
	return Missiles
	
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
		var boxRes = Inventory_Box_Res.new()
		boxes[ShipPart.ShipPartType.INVENTORY].append(boxRes)
		boxRes.Initialise(self)

		#InventoryBoxParent.columns = min(2, CharInvSpace)
	
	for g in CharEngineSpace:
		var boxRes = Inventory_Box_Res.new()
		boxes[ShipPart.ShipPartType.ENGINE].append(boxRes)
		boxRes.Initialise(self)

		#EngineInventoryBoxParent.columns = min(2, CharEngineSpace)
	
	for g in CharSensorSpace:
		var boxRes = Inventory_Box_Res.new()
		boxes[ShipPart.ShipPartType.SENSOR].append(boxRes)
		boxRes.Initialise(self)

		#SensorInventoryBoxParent.columns = min(2, CharSensorSpace)
	
	for g in CharFuelTankSpace:
		var boxRes = Inventory_Box_Res.new()
		boxes[ShipPart.ShipPartType.FUEL_TANK].append(boxRes)
		boxRes.Initialise(self)

		#FuelTankInventoryBoxParent.columns = min(2, CharFuelTankSpace)
	
	for g in CharShieldSpace:
		var boxRes = Inventory_Box_Res.new()
		boxes[ShipPart.ShipPartType.SHIELD].append(boxRes)
		boxRes.Initialise(self)

		#ShieldInventoryBoxParent.columns = min(2, CharShieldSpace)
	
	for g in CharWeaponSpace:
		var boxRes = Inventory_Box_Res.new()
		boxes[ShipPart.ShipPartType.WEAPON].append(boxRes)
		boxRes.Initialise(self)
		
		#WeaponInventoryBoxParent.columns = min(2, CharWeaponSpace)
		
	CaptainNameLabel.text = CharName
	if (interface != null):
		interface.InitialiseInventory(self)

static func newInv(Cha : Captain) -> CharacterInventory:
	var inv = CharacterInventory.new()
	inv.InitialiseStarting(Cha)
	return inv

func InitialiseStarting(Cha : Captain) -> void:

	var CharInvSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.INVENTORY_SPACE)
	var CharEngineSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.ENGINES_SLOTS)
	var CharSensorSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.SENSOR_SLOTS)
	var CharFuelTankSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK_SLOTS)
	var CharShieldSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.SHIELD_SLOTS)
	var CharWeaponSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.WEAPON_SLOTS)
	
	for g in CharInvSpace:
		var boxRes = Inventory_Box_Res.new()
		boxes[ShipPart.ShipPartType.INVENTORY].append(boxRes)
		boxRes.Initialise(self)

	
	for g in CharEngineSpace:
		var boxRes = Inventory_Box_Res.new()
		boxes[ShipPart.ShipPartType.ENGINE].append(boxRes)
		boxRes.Initialise(self)

	
	for g in CharSensorSpace:
		var boxRes = Inventory_Box_Res.new()
		boxes[ShipPart.ShipPartType.SENSOR].append(boxRes)
		boxRes.Initialise(self)

	
	for g in CharFuelTankSpace:
		var boxRes = Inventory_Box_Res.new()
		boxes[ShipPart.ShipPartType.FUEL_TANK].append(boxRes)
		boxRes.Initialise(self)

	
	for g in CharShieldSpace:
		var boxRes = Inventory_Box_Res.new()
		boxes[ShipPart.ShipPartType.SHIELD].append(boxRes)
		boxRes.Initialise(self)

	
	for g in CharWeaponSpace:
		var boxRes = Inventory_Box_Res.new()
		boxes[ShipPart.ShipPartType.WEAPON].append(boxRes)
		boxRes.Initialise(self)

	
	for It in Cha.StartingItems:
		var boxeList = boxes[It.PartType]

		var Empty : Inventory_Box_Res = null
		for g : Inventory_Box_Res in boxeList:
			if (g.IsEmpty()):
				if (Empty == null):
					Empty = g
				continue
			if (g.GetContainedItemName() == It.ItemName and g.HasSpace()):
				g.UpdateAmm(1)
				_InventoryContents[It] += 1

				break
		#try to find empty box
		if (Empty != null):
			Empty.RegisterItem(It)
			Empty.UpdateAmm(1)
			if (_InventoryContents.has(It)):
				_InventoryContents[It] += 1
			else:
				_InventoryContents[It] = 1

			#if (It is not ShipPart):
				#
				#var BoxParent = InventoryBoxParent
				#if (Empty.get_parent() != BoxParent):
					#Empty.get_parent().remove_child(Empty)
					#BoxParent.add_child(Empty)
			#
			continue
	if (interface != null):
		interface.InitialiseInventory(self)


func ItemSelected(Box : Inventory_Box_Res) -> void:
	BoxSelected.emit(Box, self)

func FindBox(It : Item) -> Inventory_Box_Res:
	var boxeList = boxes[It.PartType]

	var Empty : Inventory_Box_Res = null
	#try to find matching box for it and if not put it on any empty ones we found
	for g : Inventory_Box_Res in boxeList:
		if (g.IsEmpty()):
			if (Empty == null):
				Empty = g
			continue
		if (g.GetContainedItemName() == It.ItemName and g.HasSpace()):
			return g
	#try to find empty box
	if (Empty != null):
		return Empty

	return null

func AddItem(It : Item) -> void:
	var boxeList = boxes[It.PartType]

	var Empty : Inventory_Box_Res = null

	#try to find matching box for it and if not put it on any empty ones we found
	for g : Inventory_Box_Res in boxeList:
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
		#else:
			#var BoxParent = InventoryBoxParent
			#if (Empty.get_parent() != BoxParent):
				#Empty.get_parent().remove_child(Empty)
				#BoxParent.add_child(Empty)
		OnItemAdded.emit(It)
		InventoryUpdated.emit()
		
		return
	ItemPlecementFailed.emit(It)
	return

func AddItemToBox(It : Item, destination : Inventory_Box_Res) -> void:
	if (destination.IsEmpty()):
		destination.RegisterItem(It)
		destination.UpdateAmm(1)
		if (_InventoryContents.has(It)):
			_InventoryContents[It] += 1
		else:
			_InventoryContents[It] = 1

			
		if (It is ShipPart):
			OnShipPartAdded.emit(It)

		OnItemAdded.emit(It)
		InventoryUpdated.emit()
	else:
		destination.UpdateAmm(1)
		_InventoryContents[It] += 1

		OnItemAdded.emit(It)
		InventoryUpdated.emit()

	
func HasSpaceForItem(It : Item) -> bool:
	var boxeList = boxes[It.PartType]

	#try to find matching box for it and if not put it on any empty ones we found
	for g : Inventory_Box_Res in boxeList:
		if (g.IsEmpty()):
			return true
		if (g.GetContainedItemName() == It.ItemName and g.HasSpace()):
			return true
	return false

func GetBoxContainingItem(It : Item) -> Inventory_Box_Res:
	var boxeList = boxes[It.PartType]
	
	var Box : Inventory_Box_Res
	
	for g : Inventory_Box_Res in boxeList:
		if (g.IsEmpty()):
			continue
		if (g.GetContainedItem().IsSame(It)):
			Box = g
			
	return Box
#called for Item Descriptor once the Drop button is pressed. Signal is connected through Inventory manager when descriptor is created.
func RemoveItemFromBox(Box : Inventory_Box_Res) -> void:
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
	for boxList : Array in boxes.values():
		for g : Inventory_Box_Res in boxList:
			if (g.IsEmpty()):
				continue
			if (g._ContainedItem.ItemName == It.ItemName):
				RemoveItemFromBox(g)
				
				return


func UpgradeItem(Box : Inventory_Box_Res) -> void:
	
	#else :if (!Player.cu):
		#PopUpManager.GetInstance().DoFadeNotif("Cant upgrade ship in current port.")
		#return
	ItemUpgrade.emit(Box, self)


func TransferItem(Box : Inventory_Box_Res) -> void:
	ItemTransf.emit(Box, self)

func StartUpgrade(Box : Inventory_Box_Res) -> void:
	var Part = Box.GetContainedItem() as ShipPart
	_UpgradeTime = Part.UpgradeVersion.UpgradeTime
	_ItemBeingUpgraded = Box
	set_physics_process(true)

func StartEquip(_Box : Inventory_Box_Res, It : ShipPart) -> Inventory_Box_Res:
	_ItemBeingEquipped = It
	_EquipLocation = FindBox(It)
	_EquipTime = It.UpgradeTime
	set_physics_process(true)
	return _EquipLocation

func ReStartEquip(It : ShipPart, EquipTime : float) -> void:
	_ItemBeingEquipped = It
	_EquipLocation = FindBox(It)
	_EquipTime = EquipTime
	set_physics_process(true)

func ReStartUpgrade(Box : Inventory_Box_Res, UpTime : float) -> void:
	#var Part = Box.GetContainedItem() as ShipPart
	_UpgradeTime = UpTime
	_ItemBeingUpgraded = Box
	set_physics_process(true)
	
func _physics_process(delta: float) -> void:
	if (SimPaused or inventoryOwner.CurrentPort == null):
		return

	#_UpgradeTime -= (delta * 10)
	if (_ItemBeingUpgraded != null):
		var upgradeProgress = (delta * 10) * SimulationManager.SimSpeed()
		if (inventoryOwner.CurrentPort.HasUpgrade()):
			upgradeProgress *= 2
		_UpgradeTime -= upgradeProgress
		if (_UpgradeTime <= 0):
			ItemUpgradeFinished()
	
	if (_ItemBeingEquipped != null):
		var equipProgress = (delta * 10) * SimulationManager.SimSpeed()
		if (inventoryOwner.CurrentPort.HasUpgrade()):
			equipProgress *= 2
		_EquipTime -= equipProgress
		if (_EquipTime <= 0):
			ItemEquipFinished()
	
	set_physics_process(_UpgradeTime > 0 or _EquipTime > 0)

func CancelUpgrade() -> void:
	_ItemBeingUpgraded = null
	_UpgradeTime = 0
	set_physics_process(_UpgradeTime > 0 or _EquipTime > 0)

func CancelInstall() -> void:
	_ItemBeingEquipped = null
	_EquipLocation = null
	_EquipTime = 0
	set_physics_process(_UpgradeTime > 0 or _EquipTime > 0)

func ItemUpgradeFinished() -> void:
	var Part = _ItemBeingUpgraded.GetContainedItem() as ShipPart
	RemoveItemFromBox(_ItemBeingUpgraded)
	var UpgradedItem = Part.UpgradeVersion.duplicate(true)
	for g in Part.Upgrades.size():
		UpgradedItem.Upgrades[g].CurrentValue = Part.Upgrades[g].CurrentValue
	AddItem(UpgradedItem)
	_ItemBeingUpgraded = null
	PopUpManager.GetInstance().DoFadeNotif("{0}'s {1}\nhas succsfully been upgraded to\n{2}".format([CaptainNameLabel.text, Part.ItemName, UpgradedItem.ItemName]), null, 8)

func ItemEquipFinished() -> void:
	RemoveItemFromBox(_EquipLocation)
	AddItemToBox(_ItemBeingEquipped, _EquipLocation)
	PopUpManager.GetInstance().DoFadeNotif("{0}'s {1}\nhas succsfully been Installed".format([CaptainNameLabel.text, _ItemBeingEquipped.GetItemName()]), null, 8)

	_EquipLocation = null
	_ItemBeingEquipped = null
	

func ForceUpgradeItem(Box : Inventory_Box_Res) -> bool:
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
	if (inventoryOwner.CurrentPort.HasUpgrade()):
		return _UpgradeTime / 2.0
	return _UpgradeTime

func GetEquipTimeLeft() -> float:
	if (inventoryOwner.CurrentPort.HasUpgrade()):
		return _EquipTime / 2.0
	return _EquipTime

func GetItemBeingUpgraded() -> Inventory_Box_Res:
	return _ItemBeingUpgraded


func _on_button_pressed() -> void:
	OnCharacterInspectionPressed.emit()

func _on_deck_pressed() -> void:
	OnCharacterDeckInspectionPressed.emit()

func _on_inventory_vis_toggle_pressed() -> void:
	OnCharacterInventoryInspectionPressed.emit()

	#$VBoxContainer2/VBoxContainer/HBoxContainer2/VBoxContainer/InventoryVisToggle.disabled = true
	#var prevc = custom_minimum_size.y
	#custom_minimum_size.y = 0
#
	#var Show = !interface.visible
	#interface.visible = !interface.visible
#
	#var TargetSize
	#if (Show):
		#TargetSize = 500
		#interface.visible = !interface.visible
	#else:
		#TargetSize = 0
		#custom_minimum_size.y = prevc
		#
	#var Tw = create_tween()
	#Tw.set_ease(Tween.EASE_OUT)
	#Tw.set_trans(Tween.TRANS_QUAD)
	#Tw.tween_property(self, "custom_minimum_size", Vector2(0,TargetSize), 0.5)
	#
	#await Tw.finished
	#if (Show):
		#interface.visible = !interface.visible

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

extends PanelContainer

class_name CharacterInventory

@export_group("Nodes")
@export var InventoryBoxScene : PackedScene
@export var EngineInventoryBoxParent : GridContainer
@export var SensorInventoryBoxParent : GridContainer
@export var FuelTankInventoryBoxParent : GridContainer
@export var WeaponInventoryBoxParent : GridContainer
@export var ShieldInventoryBoxParent : GridContainer
@export var InventoryBoxParent : GridContainer
@export var CaptainNameLabel : Label

signal OnItemAdded(it : Item)
signal OnItemRemoved(it : Item)
signal OnShipPartAdded(it : ShipPart)
signal OnShipPartRemoved(it : ShipPart)
signal ItemPlecementFailed(it : Item)
signal BoxSelected(Box : Inventory_Box, OwnerInventory : CharacterInventory)
signal ItemUpgrade(Box : Inventory_Box, OwnerInventory : CharacterInventory)
signal ItemTransf(Box : Inventory_Box, OwnerInventory : CharacterInventory)
signal OnCharacterInspectionPressed
var _InventoryContents : Dictionary

var _CardInventory : Dictionary
var _CardAmmo : Dictionary

var SimPaused : bool = false
#var SimSpeed : int = 1
var _ItemBeingUpgraded : Inventory_Box
var _UpgradeTime : float

var OriginalSize : float

func _ready() -> void:
	OriginalSize = size.y
	InventoryBoxParent.get_parent().get_parent().visible = false
	#MissileDockEventH.connect("MissileLaunched", RemoveItem)
	set_physics_process(_ItemBeingUpgraded != null)

func GetCards() -> Dictionary:
	var CardsInInventory : Dictionary = {}
	for C : CardStats in _CardInventory.keys():
		for z : CardStats in CardsInInventory:
			if (z.CardName == C.CardName and z.Tier < C.Tier):
				CardsInInventory.erase(z)
				break
		if (C.RequiredPart.size() > 0):
			for P in C.RequiredPart:
				if (HasItem(P)):
					CardsInInventory[C] = _CardInventory[C]
					break
			continue
		CardsInInventory[C] = _CardInventory[C]
	return CardsInInventory

func GetCardAmmo() -> Dictionary:
	return _CardAmmo.duplicate()

func HasItem(It : Item) -> bool:
	for g in _InventoryContents.keys():
		var it = g as Item
		if (it.resource_path == It.resource_path):
			return true
	return false

func GetInventoryContents() -> Dictionary:
	return _InventoryContents

func InitialiseInventory(Cha : Captain) -> void:
	var CharInvSpace = Cha.GetStatFinalValue(STAT_CONST.STATS.INVENTORY_SPACE)
	var CharName = Cha.CaptainName
	for g in CharInvSpace:
		var Box = InventoryBoxScene.instantiate() as Inventory_Box
		Box.Initialise(self)
		InventoryBoxParent.add_child(Box)
		Box.connect("ItemSelected", ItemSelected)
	CaptainNameLabel.text = CharName

func ItemSelected(Box : Inventory_Box) -> void:
	BoxSelected.emit(Box, self)

func AddItem(It : Item) -> void:
	var boxes = _GetInventoryBoxes()
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
			if (It.CardProviding.size() > 0):
				for c in It.CardProviding:
					_CardInventory[c] += 1
			if (It.CardOptionProviding != null):
				_CardAmmo[It.CardOptionProviding] += 1
			#print("Added 1 {0}".format([It.ItemName]))
			#if (It is MissileItem):
				#MissileDockEventH.MissileAdded.emit(It)
			return
	#try to find empty box
	if (Empty != null):
		Empty.RegisterItem(It)
		Empty.UpdateAmm(1)
		if (_InventoryContents.has(It)):
			_InventoryContents[It] += 1
		else:
			_InventoryContents[It] = 1
		
		if (It.CardProviding.size() > 0):
			for c in It.CardProviding:
				if (_CardInventory.has(c)):
					_CardInventory[c] += 1
				else:
					_CardInventory[c] = 1
				
		if (It.CardOptionProviding != null):
			_CardAmmo[It.CardOptionProviding] = 1
			
		if (It is ShipPart):
			var BoxParent = GetBoxParentForType(It.PartType)
			if (Empty.get_parent() != BoxParent):
				Empty.get_parent().remove_child(Empty)
				BoxParent.add_child(Empty)
			OnShipPartAdded.emit(It)
		else:
			var BoxParent = InventoryBoxParent
			if (Empty.get_parent() != BoxParent):
				Empty.get_parent().remove_child(Empty)
				BoxParent.add_child(Empty)
		OnItemAdded.emit(It)
		#print("Added 1 {0}".format([It.ItemName]))
		#if (It is MissileItem):
			#MissileDockEventH.MissileAdded.emit(It)
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
	else : if (PartType == ShipPart.ShipPartType.NORMAL):
		BoxParent = InventoryBoxParent
	return BoxParent
	
func HasSpaceForItem(It : Item) -> bool:
	var boxes = _GetInventoryBoxes()
	#try to find matching box for it and if not put it on any empty ones we found
	for g in boxes:
		if (g.IsEmpty()):
			return true
		if (g.GetContainedItemName() == It.ItemName and g.HasSpace()):
			return true
	return false
	
#called for Item Descriptor once the Drop button is pressed. Signal is connected through Inventory manager when descriptor is created.
func RemoveItemFromBox(Box : Inventory_Box) -> void:
	var It = Box.GetContainedItem()
	if (It is ShipPart):
		OnShipPartRemoved.emit(It)
	OnItemRemoved.emit(It)
	#if (It is MissileItem):
		#MissileDockEventH.MissileRemoved.emit(It)
	Box.UpdateAmm(-1)
	#print("Removed 1 {0}".format([It.ItemName]))
	_InventoryContents[It] -= 1
	if (It.CardProviding.size() > 0):
		for g in It.CardProviding:
			_CardInventory[g] -= 1
			if (_CardInventory[g] == 0):
				_CardInventory.erase(g)
	if (It.CardOptionProviding != null):
		_CardAmmo[It.CardOptionProviding] = 1
		if (_CardAmmo[It.CardOptionProviding] == 0):
			_CardAmmo.erase(It.CardOptionProvidin)
	if (_InventoryContents[It] == 0):
		_InventoryContents.erase(It)
	if (Box.IsEmpty()):
		var BoxParent = InventoryBoxParent
		if (Box.get_parent() != BoxParent):
			Box.get_parent().remove_child(Box)
			BoxParent.add_child(Box)
	
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
	if (_ItemBeingUpgraded != null):
		PopUpManager.GetInstance().DoFadeNotif("Ship is already upgrading a part.")
		#print("Ship is already upgrading a part. Wait for it to finish first.")
		return
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
	
func _physics_process(delta: float) -> void:
	if (SimPaused):
		return
	_UpgradeTime -= (delta * 10) * SimulationManager.SimSpeed()
	#_UpgradeTime -= (delta * 10)
	if (_UpgradeTime <= 0):
		ItemUpgradeFinished()
		set_physics_process(false)

func CancelUpgrade() -> void:
	_ItemBeingUpgraded = null
	set_physics_process(false)

func ItemUpgradeFinished() -> void:
	var Part = _ItemBeingUpgraded.GetContainedItem() as ShipPart
	RemoveItemFromBox(_ItemBeingUpgraded)
	for g in Part.Upgrades.size():
		Part.UpgradeVersion.Upgrades[g].CurrentValue = Part.Upgrades[g].CurrentValue
	AddItem(Part.UpgradeVersion)
	_ItemBeingUpgraded = null

func ForceUpgradeItem(Box : Inventory_Box) -> bool:
	var Part = Box.GetContainedItem() as ShipPart
	
	if (Part == null):
		return false
	
	if (Part.UpgradeVersion == null):
		return false
	
	RemoveItemFromBox(Box)
	for g in Part.Upgrades.size():
		Part.UpgradeVersion.Upgrades[g].CurrentValue = Part.Upgrades[g].CurrentValue
	AddItem(Part.UpgradeVersion)
	
	return true

func GetUpgradeTimeLeft() -> float:
	return _UpgradeTime

func GetItemBeingUpgraded() -> Inventory_Box:
	return _ItemBeingUpgraded


func _on_button_pressed() -> void:
	OnCharacterInspectionPressed.emit()


func _on_inventory_vis_toggle_pressed() -> void:
	$VBoxContainer2/VBoxContainer/HBoxContainer2/VBoxContainer/InventoryVisToggle.disabled = true
	var prevc = custom_minimum_size.y
	custom_minimum_size.y = 0
	var Show = !InventoryBoxParent.get_parent().get_parent().visible
	InventoryBoxParent.get_parent().get_parent().visible = !InventoryBoxParent.get_parent().get_parent().visible
	var TargetSize
	if (Show):
		TargetSize = 500
		InventoryBoxParent.get_parent().get_parent().visible = !InventoryBoxParent.get_parent().get_parent().visible
	else:
		TargetSize = OriginalSize
		custom_minimum_size.y = prevc
		
	var Tw = create_tween()
	Tw.set_ease(Tween.EASE_OUT)
	Tw.set_trans(Tween.TRANS_QUAD)
	Tw.tween_property(self, "custom_minimum_size", Vector2(0,TargetSize), 0.5)
	
	await Tw.finished
	if (Show):
		InventoryBoxParent.get_parent().get_parent().visible = !InventoryBoxParent.get_parent().get_parent().visible

	if (InventoryBoxParent.get_parent().get_parent().visible):
		$VBoxContainer2/VBoxContainer/HBoxContainer2/VBoxContainer/InventoryVisToggle.text = "Hide Inventory"
	else:
		$VBoxContainer2/VBoxContainer/HBoxContainer2/VBoxContainer/InventoryVisToggle.text = "Show Inventory"
	
	$VBoxContainer2/VBoxContainer/HBoxContainer2/VBoxContainer/InventoryVisToggle.disabled = false

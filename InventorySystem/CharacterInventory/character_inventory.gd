extends VBoxContainer

class_name CharacterInventory

@export_group("Nodes")
@export var InventoryBoxScene : PackedScene
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

var SimPaused : bool = false
var SimSpeed : int = 1
var _ItemBeingUpgraded : Inventory_Box
var _UpgradeTime : float

func _ready() -> void:
	#MissileDockEventH.connect("MissileLaunched", RemoveItem)
	set_physics_process(_ItemBeingUpgraded != null)

func GetCards() -> Dictionary:
	return _CardInventory.duplicate()

func GetInventoryContents() -> Dictionary:
	return _InventoryContents

func InitialiseInventory(Cha : Captain) -> void:
	var CharInvSpace : int = Cha.GetStatFinalValue("INVENTORY_CAPACITY")
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
			if (It.CardProviding != null):
				_CardInventory[It.CardProviding] += 1
			print("Added 1 {0}".format([It.ItemName]))
			#if (It is MissileItem):
				#MissileDockEventH.MissileAdded.emit(It)
			return
	#try to find empty box
	if (Empty != null):
		Empty.RegisterItem(It)
		Empty.UpdateAmm(1)
		_InventoryContents[It] = 1
		if (It.CardProviding != null):
			_CardInventory[It.CardProviding] = 1
		if (It is ShipPart):
			OnShipPartAdded.emit(It)
		OnItemAdded.emit(It)
		print("Added 1 {0}".format([It.ItemName]))
		#if (It is MissileItem):
			#MissileDockEventH.MissileAdded.emit(It)
		return
	ItemPlecementFailed.emit(It)
	return

func HasItem(It : Item) -> bool:
	return _InventoryContents.has(It)

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
	print("Removed 1 {0}".format([It.ItemName]))
	_InventoryContents[It] -= 1
	if (It.CardProviding != null):
		var c = It.CardProviding
		_CardInventory[c] -= 1
		if (_CardInventory[c] == 0):
			_CardInventory.erase(c)
	if (_InventoryContents[It] == 0):
		_InventoryContents.erase(It)
	
func RemoveItem(It : Item) -> void:
	for g in _GetInventoryBoxes():
		var box = g as Inventory_Box
		if (box.IsEmpty()):
			continue
		if (box.GetContainedItemName() == It.ItemName):
			RemoveItemFromBox(box)
			return

func _GetInventoryBoxes() -> Array:
	return InventoryBoxParent.get_children()

func UpgradeItem(Box : Inventory_Box) -> void:
	if (_ItemBeingUpgraded != null):
		#PopUpManager.GetInstance().DoFadeNotif("Ship is already upgrading a part. Wait for it to finish first.")
		print("Ship is already upgrading a part. Wait for it to finish first.")
		return
	#else :if (!Player.cu):
		#PopUpManager.GetInstance().DoFadeNotif("Cant upgrade ship in current port.")
		#return
	ItemUpgrade.emit(Box, self)
	

func TransferItem(Box : Inventory_Box) -> void:
	ItemTransf.emit(Box, self)

func StartUpgrade(Box : Inventory_Box) -> void:
	var Part = Box.GetContainedItem() as ShipPart
	_UpgradeTime = Part.UpgradeTime
	_ItemBeingUpgraded = Box
	set_physics_process(true)
	
func _physics_process(delta: float) -> void:
	if (SimPaused):
		return
	_UpgradeTime -= (delta * 10) * SimSpeed
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
		Part.UpgradeVersion.Upgrades[g].CurrentVal = Part.Upgrades[g].CurrentVal
	AddItem(Part.UpgradeVersion)
	_ItemBeingUpgraded = null

func GetUpgradeTimeLeft() -> float:
	return _UpgradeTime

func GetItemBeingUpgraded() -> Inventory_Box:
	return _ItemBeingUpgraded


func _on_button_pressed() -> void:
	OnCharacterInspectionPressed.emit()

extends Control

class_name InventoryManager

@export_group("Scenes")
@export var CharInvScene : PackedScene
@export var ItemDescriptorScene : PackedScene
@export var ItemTransferScene : PackedScene
@export var ItemNotifScene : PackedScene
@export_group("Nodes")
@export var CharStatPanel : Control
@export var CharacterPlace : Control
@export var DescriptorPlace : Control
@export var ShipStats : InventoryShipStats
@export var ShipDeck : ShipDeckViz
@export var InvScrol : ScrollContainer
@export_group("Event Handlers")
@export var MissileDockEventH : MissileDockEventHandler
@export var DroneDockEventH : DroneDockEventHandler

var _CharacterInventories : Dictionary
var SimPaused : bool = false
#var SimSpeed : float = 1

signal InventoryToggled(t : bool)

static var Instance : InventoryManager

static func GetInstance() -> InventoryManager:
	return Instance

func _ready() -> void:
	MissileDockEventH.connect("MissileLaunched", OnMissileLaunched)
	DroneDockEventH.connect("DroneAdded", DroneAdded)
	Instance = self

func GetCharacterInventory(Cha : Captain) -> CharacterInventory:
	if (_CharacterInventories.has(Cha)):
		return _CharacterInventories[Cha]
	return null

func GetCharacterInventoryByName(CharName : String) -> CharacterInventory:
	for g in _CharacterInventories:
		if (g.CaptainName.to_lower() == CharName.to_lower()):
			return _CharacterInventories[g]
	return null

func GetCharacterByName(CharName : String) -> Captain:
	for g in _CharacterInventories:
		if (g.CaptainName.to_lower() == CharName.to_lower()):
			return g
	return null
	
func OnMissileLaunched(Mis : MissileItem, Target : Captain, _User : Captain):
	var CharacterInv = _CharacterInventories[Target] as CharacterInventory
	CharacterInv.RemoveItem(Mis)

func RemoveItemFromFleet(It : Item, Command : MapShip) -> void:
	var Captains : Array[Captain] = []
	Captains.append(Command.Cpt)
	for g in Command.GetDroneDock().DockedDrones:
		Captains.append(g.Cpt)
	
	for g in Captains:
		var Inv = GetCharacterInventory(g)
		if (Inv.HasItem(It)):
			Inv.RemoveItem(It)
			return

func FleetHasSpace(It : Item, Command : MapShip) -> bool:
	var Captains : Array[Captain] = []
	Captains.append(Command.Cpt)
	for g in Command.GetDroneDock().DockedDrones:
		Captains.append(g.Cpt)
	for g in Captains:
		var Inv = GetCharacterInventory(g)
		if (Inv.HasSpaceForItem(It)):
			return true
	return false

func AddItemToFleet(It : Item, Command : MapShip) -> void:
	var Captains : Array[Captain] = []
	Captains.append(Command.Cpt)
	for g in Command.GetDroneDock().DockedDrones:
		Captains.append(g.Cpt)
	
	for g in Captains:
		var Inv = GetCharacterInventory(g)
		if (Inv.HasSpaceForItem(It)):
			Inv.AddItem(It)
			return

func GetAllItemsInFleet(Command : MapShip) -> Array[Item]:
	var Captains : Array[Captain] = []
	Captains.append(Command.Cpt)
	for g in Command.GetDroneDock().DockedDrones:
		Captains.append(g.Cpt)
	
	var Items : Array[Item] = []
	
	for g in Captains:
		var InvContents = GetCharacterInventory(g).GetInventoryContents()
		for It in InvContents.keys():
			for Am in InvContents[It]:
				Items.append(It)
	
	return Items

func OnSimulationPaused(t : bool) -> void:
	SimPaused = t
	for g in _CharacterInventories.values():
		g.SimPaused = t
#func OnSimulationSpeedChanged(i : float) -> void:
	#SimSpeed = i
	#for g in _CharacterInventories.values():
		#g.SimSpeed = i
func BoxSelected(Box : Inventory_Box, OwnerInventory : CharacterInventory) -> void:
	var descriptors = get_tree().get_nodes_in_group("ItemDescriptor")
	if (descriptors.size() > 0):
		var desc = descriptors[0] as ItemDescriptor
		DescriptorPlace.remove_child(desc)
		desc.queue_free()
		if (desc.DescribedContainer == Box):
			CharStatPanel.visible = true
			return
	
	var Descriptor = ItemDescriptorScene.instantiate() as ItemDescriptor
	
	DescriptorPlace.add_child(Descriptor)
	CharStatPanel.visible = false
	var cpt = GetBoxOwner(Box)
	var HasUp = false
	if (cpt.CurrentPort != ""):
		var cit = GetCity(cpt.CurrentPort)
		HasUp = cit.HasUpgrade()
	Descriptor.SetData(Box, HasUp)
	#Descriptor.connect("ItemUsed", UseItem)
	Descriptor.connect("ItemUpgraded", OwnerInventory.UpgradeItem)
	Descriptor.connect("ItemDropped", OwnerInventory.RemoveItemFromBox)
	Descriptor.connect("ItemTransf", ItemTranfer)
	#Descriptor.connect("ItemRepaired", RepairPart)

func GetCity(CityName : String) -> MapSpot:
	var cities = get_tree().get_nodes_in_group("City")
	var CorrectCity : MapSpot
	for g in cities:
		var cit = g as MapSpot
		if (cit.GetSpotName() == CityName):
			CorrectCity = cit
			break
	return CorrectCity

func ItemUpdgrade(Box : Inventory_Box, OwnerInventory : CharacterInventory) -> void:
	var Cpt = GetBoxOwner(Box)
	if (Cpt.CurrentPort == ""):
		PopUpManager.GetInstance().DoFadeNotif("Ship needs to be docked to upgrade")
		return
	var It = Box.GetContainedItem() as ShipPart
	var cit = GetCity(Cpt.CurrentPort)
	var HasUpgrade = cit.HasUpgrade()
	var Cost = It.UpgradeCost
	if (HasUpgrade):
		Cost /= 2
	var PLWallet = World.GetInstance().PlayerWallet
	if (PLWallet.Funds < Cost):
		PopUpManager.GetInstance().DoFadeNotif("Cant pay for upgrade")
		return
	PLWallet.AddFunds(-Cost)
	OwnerInventory.StartUpgrade(Box, cit.HasUpgrade())
	CloseDescriptor()
	BoxSelected(Box, OwnerInventory)
func CancelUpgrades(Cha : Captain) -> void:
	if (_CharacterInventories.has(Cha)):
		var CharInv = _CharacterInventories[Cha] as CharacterInventory
		CharInv.CancelUpgrade()
	

func FlushInventory() -> void:
	for g in _CharacterInventories.values():
		var Inv = g as CharacterInventory
		for z in Inv._GetInventoryBoxes():
			for i in z._ContentAmmout:
				Inv.RemoveItemFromBox(z)
		Inv.queue_free()
	_CharacterInventories.clear()

func ItemTranfer(Box : Inventory_Box) -> void:
	var Cpt = GetBoxOwner(Box)
	var OwnerInventory = _CharacterInventories[Cpt] as CharacterInventory
	
	var It = Box.GetContainedItem()
	
	#TODO figure out a better design for landing so i can implement transfering of ship parts only on cities
	#if (It is ShipPart and Cpt.CaptainShip.CurrentPort == null and !Cpt.CaptainShip.Landed()):
		#PopUpManager.GetInstance().DoFadeNotif("Land ship to city to")
		#return
	
	var fleet = Cpt.CaptainShip.GetFleet()
	var AvailableCaptains : Array[Captain]
	for g : Captain in _CharacterInventories.keys():
		if (g == Cpt):
			continue
		if (!fleet.has(g.CaptainShip)):
			continue
		var inv = _CharacterInventories[g]
		if (inv.HasSpaceForItem(It)):
			AvailableCaptains.append(g)
	if (AvailableCaptains.size() == 0):
		PopUpManager.GetInstance().DoFadeNotif("No characters to transfer too")
		return
	var Transfer = ItemTransferScene.instantiate() as ItemTransfer
	add_child(Transfer)
	Transfer.SetData(AvailableCaptains)
	await Transfer.CharacterSelected
	var SelectedChar = Transfer.SelectedCharacter
	if (SelectedChar == null):
		return
	var SelectedCharInventory = _CharacterInventories[SelectedChar] as CharacterInventory
	SelectedCharInventory.AddItem(It)
	OwnerInventory.RemoveItemFromBox(Box)
	
	
func GetBoxOwner(Box : Inventory_Box) -> Captain:
	for g in _CharacterInventories.keys():
		for z in _CharacterInventories[g]._GetInventoryBoxes():
			if (z == Box):
				return g
	return null

func DroneAdded(Dr : Drone, _Target : MapShip):
	AddCharacter(Dr.Cpt)

func AddCharacter(Cha : Captain) -> void:
	var CharInv = CharInvScene.instantiate() as CharacterInventory
	Cha._CharInv = CharInv
	CharInv.InitialiseInventory(Cha)
	_CharacterInventories[Cha] = CharInv
	CharacterPlace.add_child(CharInv)
	
	CharInv.BoxSelected.connect(BoxSelected)
	CharInv.ItemUpgrade.connect(ItemUpdgrade)
	CharInv.OnItemAdded.connect(OnItemAdded.bind(Cha))
	CharInv.OnItemRemoved.connect(OnItemRemoved.bind(Cha))
	CharInv.OnShipPartAdded.connect(Cha.OnShipPartAddedToInventory)
	CharInv.OnShipPartRemoved.connect(Cha.OnShipPartRemovedFromInventory)
	CharInv.OnCharacterInspectionPressed.connect(InspectCharacter.bind(Cha))
	CharInv.OnCharacterDeckInspectionPressed.connect(InspectCharacterDeck.bind(Cha))
	
	if (ShipStats.CurrentShownCaptain == null):
		ShipStats.SetCaptain(Cha)
		ShipDeck.visible = false
		
	
	for g in Cha.StartingItems:
		CharInv.AddItem(g)
	UISoundMan.GetInstance().Refresh()

func OnCharacterRemoved(Cha : Captain) -> void:
	var Inv = _CharacterInventories[Cha] as CharacterInventory
	for z in Inv._GetInventoryBoxes():
		for i in z._ContentAmmout:
			Inv.RemoveItemFromBox(z)
	Inv.queue_free()
	_CharacterInventories.erase(Cha)
	
func LoadCharacter(Cha : Captain, LoadedItems : Array[ItemContainer]) -> void:
	var CharInv
	
	if (_CharacterInventories.has(Cha)):
		CharInv = _CharacterInventories[Cha]
	else:
		CharInv = CharInvScene.instantiate() as CharacterInventory
		CharInv.InitialiseInventory(Cha)
		_CharacterInventories[Cha] = CharInv
		CharacterPlace.add_child(CharInv)
	
		CharInv.connect("BoxSelected", BoxSelected)
		CharInv.connect("ItemUpgrade", ItemUpdgrade)
		CharInv.connect("OnItemAdded", OnItemAdded.bind(Cha))
		CharInv.connect("OnItemRemoved", OnItemRemoved.bind(Cha))
		CharInv.connect("OnShipPartAdded", Cha.OnShipPartAddedToInventory)
		CharInv.connect("OnShipPartRemoved", Cha.OnShipPartRemovedFromInventory)
		CharInv.connect("OnCharacterInspectionPressed", InspectCharacter.bind(Cha))
		
	Cha._CharInv = CharInv
	
	for g in CharInv._GetInventoryBoxes():
		for z in g._ContentAmmout:
			CharInv.RemoveItemFromBox(g)
	for g in LoadedItems:
		for z in g.Ammount:
			CharInv.AddItem(g.ItemType)

func OnItemAdded(It : Item, Owner : Captain) -> void:
	if (It is MissileItem):
		MissileDockEventH.OnMissileAdded(It, Owner)
	ShipStats.UpdateValues()
	
func OnItemRemoved(It : Item, Owner : Captain) -> void:
	if (It is MissileItem):
		MissileDockEventH.OnMissileRemoved(It, Owner)
	CloseDescriptor()
	ShipStats.UpdateValues()

func InspectCharacter(Cha : Captain) -> void:
	CloseDescriptor()
	ShipStats.SetCaptain(Cha)
	ShipStats.visible = true
	ShipDeck.visible = false

func InspectCharacterDeck(Cha : Captain) -> void:
	CloseDescriptor()
	ShipStats.visible = false
	ShipDeck.SetDeck(Cha)
	ShipDeck.visible = true
func CloseDescriptor() -> void:
	var descriptors = get_tree().get_nodes_in_group("ItemDescriptor")
	if (descriptors.size() > 0):
		DescriptorPlace.remove_child(descriptors[0])
		descriptors[0].queue_free()
	CharStatPanel.visible = true

func GenerateCaptainSaveData(Cpt: Captain, Inv : CharacterInventory) -> SD_CharacterInventory:
	var Data = SD_CharacterInventory.new()
	Data.Cpt = Cpt
	Data.Fuel = Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
	Data.Hull = Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL)
	var Contents = Inv.GetInventoryContents()
	for g in Contents.keys():
		var Ic = ItemContainer.new()
		Ic.ItemType = g
		Ic.Ammount = Contents[g]
		Data.Items.append(Ic)
	return Data
	
	
func GetSaveData() ->SaveData:
	var dat = SaveData.new()
	dat.DataName = "InventoryContents"
	var Datas : Array[Resource] = []
	for g in _CharacterInventories.keys():
		Datas.append(GenerateCaptainSaveData(g, _CharacterInventories[g]))
	dat.Datas = Datas
	return dat
	
func LoadSaveData(Data : SaveData) -> void:
	#FlushInventory()
	for g in Data.Datas:
		var dat = g as SD_CharacterInventory
		#call_deferred("LoadCharacter", dat.Cpt, dat.Items)
		LoadCharacter(dat.Cpt, dat.Items)
		dat.Cpt.LoadStats(dat.Fuel, dat.Hull)

var ToggleTween : Tween

func ToggleInventory() -> void:
	if (is_instance_valid(ToggleTween)):
		ToggleTween.kill()
	visible = !visible
	InventoryToggled.emit(!visible)
	$AudioStreamPlayer.play()
	ToggleTween = create_tween()
	if (visible):
		size = Vector2(size.x, 0)
		ToggleTween.set_ease(Tween.EASE_OUT)
		ToggleTween.set_trans(Tween.TRANS_QUAD)
		ToggleTween.tween_property(self, "size", Vector2(size.x, get_viewport_rect().size.y), 0.15)
		await ToggleTween.finished
		if (!ActionTracker.IsActionCompleted(ActionTracker.Action.INVENTORY_OPEN)):
			ActionTracker.OnActionCompleted(ActionTracker.Action.INVENTORY_OPEN)
			InventoryTutorial()
	else:
		visible = !visible
		ToggleTween.set_ease(Tween.EASE_OUT)
		ToggleTween.set_trans(Tween.TRANS_QUAD)
		ToggleTween.tween_property(self, "size", Vector2(size.x, 0), 0.15)
		await ToggleTween.finished
		visible = !visible

func InventoryTutorial() -> void:
	var TutorialText = "The [color=#ffc315Inventory panel[/color] is where the details for each ship in your fleet can be found. From their stats to their inventory contents."
	ActionTracker.GetInstance().ShowTutorial("Inventory", TutorialText, [], true)

func _on_scroll_container_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		InvScrol.scroll_vertical -= event.relative.y

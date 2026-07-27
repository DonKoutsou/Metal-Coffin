extends Control

class_name TeamEquipmentSetup

@export var CaptainStatCont : CaptainStatContainer
@export var DescriptorPlace : Control
@export var ItemDescriptorScene : PackedScene
@export var PlayerCaptainLocation : Control
@export var EnemyCaptainLocation : Control
@export var Equipment : Array[Item]
@export var CaptainName : Label
@export var CaptainB : PackedScene
@export_group("ItemCatalogue")
@export var CagefightItemUI : PackedScene
@export var ItemCatalogue : Control
@export var ItemParent : Control
@export var Desc : ItemDescriptor

var CurrentCpt : Captain
var CurrentDescriptor : ItemDescriptor

func _ready() -> void:
	CaptainStatCont.InventoryBoxSelected.connect(ItemSelected) 
	CaptainStatCont.ShipInventory.KeepBoxesActive = true
	#var b = CaptainB.instantiate() as CaptainButton
	#var Cpt = load("res://Resources/Captains/PlayerCaptains/Craden.tres") as Captain
	#b.SetCpt(Cpt)
	#b.OnShipSelected.connect(OnCaptainSelected.bind(Cpt))
	#PlayerCaptainLocation.add_child(b)
	#OnCaptainSelected()

func _exit_tree() -> void:
	Clear()

func Clear() -> void:
	for g : CaptainButton in PlayerCaptainLocation.get_children():
		g.queue_free()
	for g : CaptainButton in EnemyCaptainLocation.get_children():
		g.queue_free()
	
	var descriptors = get_tree().get_nodes_in_group("ItemDescriptor")
	if (descriptors.size() > 0):
		var desc = descriptors[0] as ItemDescriptor
		DescriptorPlace.remove_child(desc)
		desc.queue_free()
	
	if (CurrentCpt != null):
		CurrentCpt._CharInv.queue_free()
	CurrentCpt = null
	CaptainStatCont.visible = false
	
	ItemCatalogue.visible = false
	for g in ItemParent.get_children():
		g.queue_free()

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
	if (CurrentCpt != null):
		CurrentCpt._CharInv.queue_free()
	#CaptainName.text = Cpt.GetCaptainName()
	var descriptors = get_tree().get_nodes_in_group("ItemDescriptor")
	if (descriptors.size() > 0):
		var desc = descriptors[0] as ItemDescriptor
		DescriptorPlace.remove_child(desc)
		desc.queue_free()
	
	Cpt.RegisterInventory(CharacterInventory.newInv(Cpt))
	
	CaptainStatCont.visible = true
	CaptainStatCont.SetCaptain(Cpt)
	CaptainStatCont.ShowStats()
	CurrentCpt = Cpt


func GetTypeOfBox(Box : Inventory_Box_Res) -> ShipPart.ShipPartType:
	var Type : ShipPart.ShipPartType = CurrentCpt.GetCharacterInventory().GetBoxType(Box)
	return Type

func ItemSelected(Box : Inventory_Box_Res, inv : CharacterInventory) -> void:
	if (CurrentDescriptor != null):
		#var desc = descriptors[0] as ItemDescriptor
		DescriptorPlace.remove_child(CurrentDescriptor)
		CurrentDescriptor.queue_free()
		
		if (CurrentDescriptor.DescribedContainer == Box):
			return
	
	CurrentDescriptor = ItemDescriptorScene.instantiate() as ItemDescriptor
	CurrentDescriptor.DescribedContainer = Box
	if (Box.IsEmpty()):
		CurrentDescriptor.SetEmptyShopData(GetTypeOfBox(Box))
	else:
		CurrentDescriptor.SetData(Box, true, false, true, true, true)
	
	CurrentDescriptor.ItemAdd.connect(AddItem)
	CurrentDescriptor.ItemUpgraded.connect(UpgradeItem)
	CurrentDescriptor.ItemRemove.connect(RemoveItem)
	CurrentDescriptor.ItemIncrease.connect(IncreaseItem)
	
	DescriptorPlace.add_child(CurrentDescriptor)

	CurrentDescriptor.set_physics_process(false)
	CurrentDescriptor.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func UpdateDescriptor(Box : Inventory_Box_Res) -> void:
	if (CurrentDescriptor != null):
		CurrentDescriptor.SetData(Box, true, false, true, true, true)

func UpgradeItem(Box : Inventory_Box_Res) -> void:
	var OriginalItem = Box.GetContainedItem() as ShipPart
	CurrentCpt.StartingItems.erase(OriginalItem)
	CurrentCpt.GetCharacterInventory().RemoveItemFromBox(Box)
	
	var UpgradedItem = OriginalItem.UpgradeVersion
	CurrentCpt.StartingItems.append(UpgradedItem)
	CurrentCpt.GetCharacterInventory().AddItemToBox(UpgradedItem, Box)

	CaptainStatCont.UpdateValues()
	
	Box.RegisterItem(UpgradedItem)
	UpdateDescriptor(Box)
	PopUpManager.GetInstance().DoFadeNotif("{0} Upgraded".format([OriginalItem.GetItemName()]))

var SelectedContainer : Inventory_Box_Res
func AddItem(Box : Inventory_Box_Res) -> void:
	SelectedContainer = Box
	var Type = GetTypeOfBox(Box)
	
	var c1 = Control.new()
	c1.custom_minimum_size.y = 200
	ItemParent.add_child(c1)
	c1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	
	var Amm : int = 0
	for g in Equipment:
		if (g is ShipPart and Type != g.PartType):
			continue
		if (g is not ShipPart and Type != ShipPart.ShipPartType.INVENTORY):
			continue
		
		var B = CagefightItemUI.instantiate() as CageFightItem
		B.Init(g)
		B.OnItemBought.connect(OnItemSelected.bind(g))
		ItemParent.add_child(B)
		Amm += 1
	
	if (Amm == 0):
		PopUpManager.GetInstance().DoFadeNotif("No available parts for slot found")
		for g in ItemParent.get_children():
			g.queue_free()
		return
		
	PopUpManager.GetInstance().DoFadeNotif("{0} combatible parts found".format([Amm]))
	ItemCatalogue.visible = true
	var c2 = Control.new()
	c2.custom_minimum_size.y = 200
	ItemParent.add_child(c2)
	c2.mouse_filter = Control.MOUSE_FILTER_IGNORE

func IncreaseItem(Box : Inventory_Box_Res) -> void:
	PopUpManager.GetInstance().DoFadeNotif("{0} Added".format([Box.GetContainedItem().GetItemName()]))
	CurrentCpt.StartingItems.append(Box.GetContainedItem())
	CurrentCpt.GetCharacterInventory().AddItem(Box.GetContainedItem())
	#DeckUI.SetDeck2(CurrentCpt)
	

func OnItemSelected(It : Item) -> void:
	ItemCatalogue.visible = false
	for g in ItemParent.get_children():
		g.queue_free()
		
	CurrentCpt.StartingItems.append(It)
	CurrentCpt.GetCharacterInventory().AddItemToBox(It, SelectedContainer)
	CaptainStatCont.UpdateValues()

	UpdateDescriptor(SelectedContainer)
	PopUpManager.GetInstance().DoFadeNotif("{0} Added".format([It.GetItemName()]))

func RemoveItem(Box : Inventory_Box_Res) -> void:
	PopUpManager.GetInstance().DoFadeNotif("{0} Removed".format([Box.GetContainedItem().GetItemName()]))
	var OriginalItem = Box.GetContainedItem()
		
	CurrentCpt.StartingItems.erase(OriginalItem)
	CurrentCpt.GetCharacterInventory().RemoveItem(OriginalItem)
	CaptainStatCont.UpdateValues()
	
	
	#DeckUI.SetDeck2(CurrentCpt)
	if (Box.IsEmpty()):
		ItemSelected(Box, null)

func _physics_process(_delta: float) -> void:
	#Going through and seeing wich Merch is closer to middle of screen and connect UI Descriptor to it
	var midpoint = get_viewport_rect().size/2
	var Closest : Control
	var Dist : float = 9999999999999999
	for g : Control in ItemParent.get_children():
		if (g is not CageFightItem):
			continue
		var NewDest = (g.global_position + (g.size / 2)).distance_squared_to(midpoint)
		if (NewDest < Dist):
			Dist = NewDest
			Closest = g
	if (Closest == null):
		return
	if (Desc.DescribedItem != Closest.Itm):
		Desc.SetMerchData(Closest.Itm, [])

func _on_cancel_button_pressed() -> void:
	ItemCatalogue.visible = false
	for g in ItemParent.get_children():
		g.queue_free()


func _on_stats_pressed() -> void:
	CaptainStatCont.ShowStats()


func _on_deck_pressed() -> void:
	CaptainStatCont.ShowDeck()


func _on_inventory_pressed() -> void:
	CaptainStatCont.ShowInvetory()

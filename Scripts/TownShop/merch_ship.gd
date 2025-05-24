extends Control

class_name MerchShop

@export var ItemScene : PackedScene
@export var Scroll : ScrollContainer
@export var ItemPlecement : Control
@export var Descriptor : ItemDescriptor
#@export var DescriptorPlecement : Control

func _on_scroll_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click") or event is InputEventScreenDrag):
		Scroll.scroll_vertical -= event.relative.y

signal ItemSold(It : Item)
signal ItemBought(It : Item)

#func _ready() -> void:
	#var M : Array[Merchandise]
	#var m1 = load("res://Resources/Merch/FireAmmo.tres")
	#m1.Amm = 10
	#M.append(m1)
	#Init([], M)

func Init(LandedShips : Array[MapShip], Merch : Array[Merchandise]) -> void:
	var Itms : Dictionary[Item, int]
	
	for g in LandedShips:
		var InvContents = g.Cpt.GetCharacterInventory().GetInventoryContents()
		for it in InvContents:
			if (Itms.has(it)):
				Itms[it] += 1
			else:
				Itms[it] = 1
	
	var C = Control.new()
	ItemPlecement.add_child(C)
	C.custom_minimum_size.y = 150
	for m : Merchandise in Merch:
		if (m.Amm == 0 and !Itms.has(m.It)):
			continue

		var ItScene = ItemScene.instantiate() as TownShopItem
		ItScene.It = m.It
		ItScene.ItPrice = m.Price
		ItScene.ShopAmm = m.Amm
		if (Itms.has(m.It)):
			ItScene.PlAmm = Itms[m.It]
		else:
			ItScene.PlAmm = 0
			
		ItScene.LandedShips = LandedShips
		ItScene.connect("OnItemBought", OnItemBought)
		ItScene.connect("OnItemSold", OnItemSold)
		#ItScene.OnItemInspected.connect(OnItemInspected)
		ItemPlecement.visible = true
		ItemPlecement.add_child(ItScene)
	var C2 = Control.new()
	ItemPlecement.add_child(C2)
	C2.custom_minimum_size.y = 150
#func OnItemInspected(It : Item) -> void:
	#var descriptors = get_tree().get_nodes_in_group("ItemDescriptor")
	#if (descriptors.size() > 0):
		#var desc = descriptors[0] as ItemDescriptor
		#DescriptorPlecement.remove_child(desc)
		#desc.queue_free()
		#if (desc.DescribedItem == It):
			#return
#
	#var Descriptor = Descriptor.instantiate() as ItemDescriptor
#
	#Descriptor.SetMerchData(It)
#
	#DescriptorPlecement.add_child(Descriptor)
	#Descriptor.set_physics_process(false)
	##Descriptor.size_flags_horizontal = Control.SIZE_EXPAND

func _physics_process(delta: float) -> void:
	var midpoint = get_viewport_rect().size/2
	var Closest : Control
	var Dist : float = 9999999
	for g : Control in ItemPlecement.get_children():
		if (g is not TownShopItem):
			continue
		var NewDest = (g.global_position + (g.size / 2)).distance_to(midpoint)
		if (NewDest < Dist):
			Dist = NewDest
			Closest = g
	if (Descriptor.DescribedItem != Closest.It):
		Descriptor.SetMerchData(Closest.It)
	
	
func OnItemSold(It : Item) -> void:
	ItemSold.emit(It)

func OnItemBought(It : Item) -> void:
	ItemBought.emit(It)

func UpdateShopItemsDetails() -> void:
	for g:TownShopItem in ItemPlecement.get_children():
		g.ToggleDetails(g.global_position.y > 0 and g.global_position.y < get_viewport_rect().size.y - 150)


func _on_leave_merch_pressed() -> void:
	queue_free()

extends Control

class_name MerchShop

@export var ItemScene : PackedScene
@export var ItemPlecement : Control
@export var Descriptor : ItemDescriptor

var AvailableShips : Array[MapShip]

signal ItemSold(It : Item)
signal ItemBought(It : Item)

func Init(LandedShips : Array[MapShip], Merch : Array[Merchandise]) -> void:
	var Itms : Dictionary[Item, int]
	AvailableShips.append_array(LandedShips)
	for ship in LandedShips:
		var InvContents = ship.Cpt.GetCharacterInventory().GetInventoryContents()
		for it in InvContents:
			if (Itms.has(it)):
				Itms[it] += InvContents[it]
			else:
				Itms[it] = InvContents[it]
	#Spacer
	var C = Control.new()
	ItemPlecement.add_child(C)
	C.custom_minimum_size.y = 150
	
	for m : Merchandise in Merch:
		#If neither player or shop has any of selected Merch dont add the UI for it
		if (m.Amm == 0 and !Itms.has(m.It)):
			continue
		
		var ItScene = ItemScene.instantiate() as TownShopItem
		
		var AmmountPlayerHas : int
		if (Itms.has(m.It)):
			AmmountPlayerHas = Itms[m.It]
		else:
			AmmountPlayerHas = 0
		Itms.erase(m.It)
		ItScene.Init(m.It, m.It.Cost, m.Amm, AmmountPlayerHas, LandedShips)
		ItScene.OnItemBought.connect(OnItemBought.bind( m.It.Cost))
		ItScene.OnItemSold.connect(OnItemSold.bind( m.It.Cost))

		ItemPlecement.visible = true
		ItemPlecement.add_child(ItScene)
	for it : Item in Itms:
		if (it is ShipPart):
			continue
		#If neither player or shop has any of selected Merch dont add the UI for it
		
		var ItScene = ItemScene.instantiate() as TownShopItem
		ItScene.Init(it, it.Cost, 0, Itms[it], LandedShips)
		ItScene.OnItemBought.connect(OnItemBought.bind( it.Cost))
		ItScene.OnItemSold.connect(OnItemSold.bind( it.Cost))

		ItemPlecement.visible = true
		ItemPlecement.add_child(ItScene)
	#End Spacer
	var C2 = Control.new()
	ItemPlecement.add_child(C2)
	C2.custom_minimum_size.y = 150


func _physics_process(_delta: float) -> void:
	#Going through and seeing wich Merch is closer to middle of screen and connect UI Descriptor to it
	var midpoint = get_viewport_rect().size/2
	var Closest : Control
	var Dist : float = 99999999999999
	for g : Control in ItemPlecement.get_children():
		if (g is not TownShopItem):
			continue
		var NewDest = (g.global_position + (g.size / 2)).distance_squared_to(midpoint)
		if (NewDest < Dist):
			Dist = NewDest
			Closest = g
	if (Descriptor.DescribedItem != Closest.It):
		Descriptor.SetMerchData(Closest.It, AvailableShips)
	
	
func OnItemSold(It : Item, Price : float) -> void:
	ItemSold.emit(It)
	Map.GetInstance().GetScreenUi().TownUI.CoinsReceived(roundi(Price / 100))
	AchievementManager.GetInstance().IncrementStatFloat("MERCHSAM", Price)

func OnItemBought(It : Item, Price : float) -> void:
	ItemBought.emit(It)
	Map.GetInstance().GetScreenUi().TownUI.DropCoins(roundi(Price / 100))
	AchievementManager.GetInstance().IncrementStatFloat("MERCHBAM", Price)
	

func _on_leave_merch_pressed() -> void:
	queue_free()

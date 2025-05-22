extends PanelContainer

class_name MerchShop

@export var ItemScene : PackedScene
@export var Scroll : ScrollContainer
@export var ItemPlecement : Control

func _on_scroll_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click") or event is InputEventScreenDrag):
		Scroll.scroll_vertical -= event.relative.y

signal ItemSold(It : Item)
signal ItemBought(It : Item)

func Init(LandedShips : Array[MapShip], Merch : Array[Merchandise]) -> void:
	var Itms : Dictionary[Item, int]
	
	for g in LandedShips:
		var InvContents = g.Cpt.GetCharacterInventory().GetInventoryContents()
		for it in InvContents:
			if (Itms.has(it)):
				Itms[it] += 1
			else:
				Itms[it] = 1
				
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
		ItemPlecement.visible = true
		ItemPlecement.add_child(ItScene)

func OnItemSold(It : Item) -> void:
	ItemSold.emit(It)

func OnItemBought(It : Item) -> void:
	ItemBought.emit(It)

func UpdateShopItemsDetails() -> void:
	for g:TownShopItem in ItemPlecement.get_children():
		g.ToggleDetails(g.global_position.y > 0 and g.global_position.y < get_viewport_rect().size.y - 150)


func _on_leave_merch_pressed() -> void:
	queue_free()

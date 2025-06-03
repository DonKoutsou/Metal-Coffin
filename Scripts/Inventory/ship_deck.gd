extends VBoxContainer

class_name ShipDeckViz

@export var CharPortrait : TextureRect
@export var CardScene : PackedScene
@export var CardPosition : Control

var CurrentlyShownCharacter : Captain

func InventoryUpdated() -> void:
	SetDeck(CurrentlyShownCharacter)

func SetDeck(Ch : Captain) -> void:
	var Inv = Ch.GetCharacterInventory()
	
	if (CurrentlyShownCharacter != Ch):
		if (CurrentlyShownCharacter != null):
			CurrentlyShownCharacter.GetCharacterInventory().InventoryUpdated.disconnect(InventoryUpdated)
		CurrentlyShownCharacter = Ch
		Inv.InventoryUpdated.connect(InventoryUpdated)
	
	for g in CardPosition.get_children():
		g.queue_free()
	
	var deck = Inv.GetCardDictionary()
	
	for card : CardStats in deck:
		var c = CardScene.instantiate() as Card
		c.SetCardStats(card, deck[card])
		CardPosition.add_child(c)
		c.Dissable()

func Clear() -> void:
	for g in CardPosition.get_children():
		g.queue_free()

func SetDeck2(Ch : Captain) -> void:
	#var Inv = Ch.GetCharacterInventory()
	
	#if (CurrentlyShownCharacter != Ch):
		#if (CurrentlyShownCharacter != null):
			#CurrentlyShownCharacter.GetCharacterInventory().InventoryUpdated.disconnect(InventoryUpdated)
		#CurrentlyShownCharacter = Ch
		#Inv.InventoryUpdated.connect(InventoryUpdated)
	
	for g in CardPosition.get_children():
		g.queue_free()
	
	var deck = Ch.GetCards()
	
	#if (CardPosition.Vertical):
		#CardPosition.custom_minimum_size.y = deck.size() * 100
	#else:
		#CardPosition.custom_minimum_size.x = deck.size() * 100
	#var ammo = Inv.GetCardAmmo()
	
	for card : CardStats in deck:
		var c = CardScene.instantiate() as Card
		c.SetCardStats(card, deck[card])
		CardPosition.add_child(c)
		c.Dissable()
	

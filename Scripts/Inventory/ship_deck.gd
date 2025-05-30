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
	
	var deck = Inv.GetCards()
	#var ammo = Inv.GetCardAmmo()
	
	for card : CardStats in deck:
		var c = CardScene.instantiate() as Card
		c.SetCardStats(card)
		CardPosition.add_child(c)
		c.Dissable()

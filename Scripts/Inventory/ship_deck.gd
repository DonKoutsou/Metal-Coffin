extends VBoxContainer

class_name ShipDeckViz

@export var CharPortrait : TextureRect
@export var CardScene : PackedScene
@export var OffensiveCardPosition : Control
@export var DeffencsiveCardPosition : Control
@export var UtilityCardPosition : Control
@export var PowerCardPosition : Control

var CurrentlyShownCharacter : Captain

var PooledCards : Array[Card] = []

func InventoryUpdated() -> void:
	if (!visible):
		return
	SetDeck(CurrentlyShownCharacter)

func _exit_tree() -> void:
	for g in PooledCards:
		g.queue_free()

func SetDeck(Ch : Captain) -> void:
	var msBefore = Time.get_ticks_msec()
	var Inv = Ch.GetCharacterInventory()

	var deck : Dictionary[CardStats, int]
	
	if (Inv != null):
		if (CurrentlyShownCharacter != Ch):
			if (CurrentlyShownCharacter != null and CurrentlyShownCharacter.GetCharacterInventory() != null):
				CurrentlyShownCharacter.GetCharacterInventory().InventoryUpdated.disconnect(InventoryUpdated)
			CurrentlyShownCharacter = Ch
			Inv.InventoryUpdated.connect(InventoryUpdated)
		deck = Inv.GetCardDictionary()
		var dispositionCards : Dictionary[CardStats, int] = DispositionManager.Instance.GetRewards(Ch)
	
		for g in dispositionCards:
			if (deck.has(g)):
				deck[g] += dispositionCards[g]
			else:
				deck[g] = dispositionCards[g]
	else:
		deck = Ch.GetStartingDeck()

	
	for g in OffensiveCardPosition.get_children():
		PooledCards.append(g)
		#OffensiveCardPosition.remove_child(g)
	for g in DeffencsiveCardPosition.get_children():
		PooledCards.append(g)
		#DeffencsiveCardPosition.remove_child(g)
	for g in UtilityCardPosition.get_children():
		PooledCards.append(g)
		#UtilityCardPosition.remove_child(g)
		#g.queue_free()
	for g in PowerCardPosition.get_children():
		PooledCards.append(g)
		#PowerCardPosition.remove_child(g)
	
	for card : CardStats in deck:
		var c : Card
		if (PooledCards.size() > 0):
			c = PooledCards.pop_back()
			var parent = c.get_parent()
			if (parent):
				c.reparent(GetParentForCard(card))
			else:
				GetParentForCard(card).add_child(c)
		else:
			c = CardScene.instantiate()
			GetParentForCard(card).add_child(c)
		c.SetCardStats(card, deck[card])
		c.Dissable()
	
	for g in PooledCards:
		var parent = g.get_parent()
		if (parent):
			g.get_parent().remove_child(g)
			
	print("Pooled = {0}".format([PooledCards.size()]))
	var msAfter = Time.get_ticks_msec()
	print("Card Setting took {0}".format([msAfter - msBefore]))

func GetParentForCard(C : CardStats) -> Control:
	match C.Type:
		CardStats.CardType.OFFENSIVE:
			return OffensiveCardPosition
		CardStats.CardType.DEFFENSIVE:
			return DeffencsiveCardPosition
		CardStats.CardType.UTILITY:
			return UtilityCardPosition
		CardStats.CardType.POWER:
			return PowerCardPosition
	return null

func Clear() -> void:
	for g in OffensiveCardPosition.get_children():
		g.queue_free()
	for g in DeffencsiveCardPosition.get_children():
		g.queue_free()
	for g in UtilityCardPosition.get_children():
		g.queue_free()

func SetDeck2(Ch : Captain) -> void:
	#var Inv = Ch.GetCharacterInventory()
	
	#if (CurrentlyShownCharacter != Ch):
		#if (CurrentlyShownCharacter != null):
			#CurrentlyShownCharacter.GetCharacterInventory().InventoryUpdated.disconnect(InventoryUpdated)
		#CurrentlyShownCharacter = Ch
		#Inv.InventoryUpdated.connect(InventoryUpdated)
	
	for g in OffensiveCardPosition.get_children():
		g.queue_free()
	for g in DeffencsiveCardPosition.get_children():
		g.queue_free()
	for g in UtilityCardPosition.get_children():
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
		GetParentForCard(card).add_child(c)
		c.Dissable()
	

extends Resource

class_name Deck

var DeckPile : Array[CardStats]
var Hand : Array[CardStats]
var DiscardPile : Array[CardStats]

func GetCardList() -> Array[CardStats]:
	var List : Array[CardStats]
	
	List.append_array(DeckPile)
	List.append_array(Hand)
	List.append_array(DiscardPile)

	return List

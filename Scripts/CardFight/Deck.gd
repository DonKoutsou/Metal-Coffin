extends Resource

class_name Deck

var DeckPile : Array[CardStats]
var Hand : Array[CardStats]
var DiscardPile : Array[CardStats]

func GetCardList() -> Dictionary[CardStats, int]:
	var List : Dictionary[CardStats, int]
	for g in DeckPile:
		if (List.has(g)):
			List[g] += 1
		else:
			List[g] = 1
	for g in Hand:
		if (List.has(g)):
			List[g] += 1
		else:
			List[g] = 1
	for g in DiscardPile:
		if (List.has(g)):
			List[g] += 1
		else:
			List[g] = 1
	return List

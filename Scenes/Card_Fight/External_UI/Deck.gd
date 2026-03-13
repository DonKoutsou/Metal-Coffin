extends Resource

class_name Deck

var DeckPile : Array[CardStats]
var Hand : Array[CardStats]
var DiscardPile : Array[CardStats]

var isShuffling : bool = false

signal Shuffling(t : bool)
signal PileChanged(t : bool)
signal DiscardChanged(t : bool)
signal OnCardDrawn(C : CardStats)
signal MultiCardDrawn(DrawnCards : Array[CardStats], discardAmm : int)
signal MultiSpecificDrawn(DrawnCards : Array[CardStats])

func GetCardList() -> Array[CardStats]:
	var List : Array[CardStats]
	
	List.append_array(DeckPile)
	List.append_array(Hand)
	List.append_array(DiscardPile)

	return List

func GetCardAmm() -> int:
	return DeckPile.size() + Hand.size() + DiscardPile.size()

func DrawMulti(drawAmm : int, discardAmm : int) -> void:
	var DrawnCards : Array[CardStats] = []

	for g in drawAmm:
		if (DeckPile.size() <= 0):
			await ShuffleDiscardedIntoDeck()
		if (DeckPile.size() <= 0):
			break
		var C = DeckPile.pop_front()
		DrawnCards.append(C)
		PileChanged.emit(false)
		
	MultiCardDrawn.emit(DrawnCards, discardAmm)

func DrawCard() -> bool:
	if (DeckPile.size() <= 0):
		await ShuffleDiscardedIntoDeck()
	if (DeckPile.size() <= 0):
		return false
	var C = DeckPile.pop_front()
	PileChanged.emit(false)
	OnCardDrawn.emit(C)
	return true

func DrawSpecific(C : CardStats) -> void:
	if (DeckPile.size() <= 0):
		await ShuffleDiscardedIntoDeck()
	if (DeckPile.size() <= 0):
		return
	
	var HasCardInDeck : bool = false
	
	for g : CardStats in DeckPile:
		if (C.IsSame(g)):
			HasCardInDeck = true
			DeckPile.erase(g)
			break

	if (!HasCardInDeck):
		return
	
	PileChanged.emit(false)
	OnCardDrawn.emit(C)

func DrawSingleOfType(type : MultiCardSpawnModule.CardType) -> void:
	var PossibleCards : Array[CardStats]
	
	for g : CardStats in DeckPile:
		var Exists : bool = false
		for C in PossibleCards:
			if (C.IsSame(g)):
				Exists = true
				break
		if (Exists):
			continue
		if (TestCard(g.OnPerformModule, type)):
			PossibleCards.append(g)
			continue
		for m in g.OnUseModules:
			if (TestCard(m, type)):
				PossibleCards.append(g)
				break
	
	MultiSpecificDrawn.emit(PossibleCards)

func TestCard(Mod : CardModule, testType : MultiCardSpawnModule.CardType) -> bool:
	if (testType == MultiCardSpawnModule.CardType.OFFENSIVE and Mod is OffensiveCardModule):
		return true
	if (testType == MultiCardSpawnModule.CardType.DEFENSIVE and Mod is DeffenceCardModule):
		return true
	return false

func DiscardCard(C : CardStats) -> void:
	#PopUpManager.GetInstance().DoFadeNotif("Card Discarded")
	DiscardPile.append(C)
	DiscardChanged.emit(true)

func ShuffleDiscardedIntoDeck(DoAnim : bool = true) -> void:
	isShuffling = true
	Shuffling.emit(true)
	PopUpManager.GetInstance().DoFadeNotif("Shuffling Deck")
	if (DoAnim):
		for g in DiscardPile.size():
			await Helper.GetInstance().wait(0.05)
			DiscardChanged.emit(false)
			#ExternalUI.DiscardPile.OnCardRemoved()
			PileChanged.emit(true)
			#ExternalUI.DeckUI.OnCardAdded(ExternalUI.DiscardPile.global_position)
				
	DeckPile.append_array(DiscardPile)
	DiscardPile.clear()
	
	DeckPile.shuffle()
	isShuffling = false
	Shuffling.emit(false)

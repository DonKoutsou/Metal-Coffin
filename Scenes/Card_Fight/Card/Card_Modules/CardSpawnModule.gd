extends CardModule
class_name CardSpawnModule

@export var CardsToSpawn : Array[CardStats]

func GetDesc(_Tier : int) -> String:
	return "Draw a {0} from the deck".format([CardsToSpawn[0].GetCardName()])

func NeedsTargetSelect() -> bool:
	return false

func Handle(Performer : BattleShipStats, Action : CardStats, _Targets : Array[BattleShipStats] = []) -> AnimationData:
	if (Action.Burned):
		return DeffensiveAnimationData.new()
	var list : Array[CardStats]
	for c in CardsToSpawn:
		var C = c.duplicate() as CardStats
		C.Tier = Action.Tier
		list.append(C)
	Performer.deck.DrawSpecificFromList(list)
	return null

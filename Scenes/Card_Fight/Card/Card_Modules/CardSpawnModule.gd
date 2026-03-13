extends CardModule
class_name CardSpawnModule

@export var CardToSpawn : CardStats

func GetDesc(_Tier : int) -> String:
	return "Draw a {0} from the deck".format([CardToSpawn.GetCardName()])

func NeedsTargetSelect() -> bool:
	return false

func Handle(Performer : BattleShipStats, Action : CardStats, Targets : Array[BattleShipStats] = []) -> AnimationData:
	if (Action.Burned):
		return DeffensiveAnimationData.new()
	var C = CardToSpawn.duplicate() as CardStats
	C.Tier = Action.Tier
	Performer.deck.DrawSpecific(C)
	return null

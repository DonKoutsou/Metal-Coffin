extends CardModule
class_name MultiCardSpawnModule

@export var CardToSpawn : CardStats.CardType

func TestCard(Mod : CardStats) -> bool:
	return Mod.Type == CardToSpawn

func GetDesc(_Tier : int) -> String:
	return "Put one {0} card from the deck to you hand.".format([CardStats.CardType.keys()[CardToSpawn]])

func NeedsTargetSelect() -> bool:
	return false

func Handle(Performer : BattleShipStats, Action : CardStats, _Targets : Array[BattleShipStats] = []) -> AnimationData:
	if (Action.Burned):
		return DeffensiveAnimationData.new()
	Performer.deck.DrawSingleOfType(CardToSpawn)
	return null

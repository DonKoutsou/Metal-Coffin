extends CardModule
class_name OffensiveCardSpawnModule

@export var CardToSpawn : CardStats

func GetDesc(Tier : int) -> String:
	return "Draw a {0} from the deck".format([CardToSpawn.GetCardName()])

func NeedsTargetSelect() -> bool:
	return false

func Handle(_Performer : BattleShipStats, Action : CardStats, Targets : Array[BattleShipStats] = []) -> AnimationData:
	if (Action.Burned):
		return DeffensiveAnimationData.new()
	return null

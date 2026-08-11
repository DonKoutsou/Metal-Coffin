extends CardModule
class_name InterceptModule

func GetDesc(Tier : int, _targetOverride : String = "") -> String:
	return "Intercept an atack aimed at a different ship."

func NeedsTargetSelect() -> bool:
	return false

func Handle(_Performer : BattleShipStats, Action : CardStats, _Targets : Array[BattleShipStats] = []) -> AnimationData:
	if (Action.Burned):
		return DeffensiveAnimationData.new()
	
	return DeffensiveAnimationData.new()

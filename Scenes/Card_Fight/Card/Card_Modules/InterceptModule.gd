extends CardModule
class_name InterceptModule

func GetDesc(_Tier : int) -> String:
	return "Intercept all currently planned atacks."

func NeedsTargetSelect() -> bool:
	return false

func Handle(_Performer : BattleShipStats, Action : CardStats, _Targets : Array[BattleShipStats] = []) -> AnimationData:
	if (Action.Burned):
		return DeffensiveAnimationData.new()
	
	return DeffensiveAnimationData.new()

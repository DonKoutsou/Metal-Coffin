extends DeffenceCardModule

class_name NullCardModule

func GetDesc(Tier : int) -> String:
	return "Null"
	
func GetBattleDesc(_User : BattleShipStats, Tier : int) -> String:
	return "Null"

func NeedsTargetSelect() -> bool:
	return false

func Handle(_Performer : BattleShipStats, Action : CardStats, Targets : Array[BattleShipStats] = []) -> AnimationData:
	if (Action.Burned):
		return DeffensiveAnimationData.new()
	var Data = DeffensiveAnimationData.new()
	Data.Mod = self
	return Data

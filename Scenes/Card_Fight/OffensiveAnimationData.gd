extends AnimationData

class_name OffensiveAnimationData

var DeffenceList : Dictionary[BattleShipStats, Dictionary]

static func NewData(Mod : CardModule, TargetList : Dictionary[BattleShipStats, Dictionary]) -> OffensiveAnimationData:
	var data = OffensiveAnimationData.new()
	data.Mod = Mod
	data.DeffenceList = TargetList
	return data

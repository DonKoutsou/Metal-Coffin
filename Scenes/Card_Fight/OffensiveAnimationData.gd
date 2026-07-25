extends AnimationData

class_name OffensiveAnimationData

var DeffenceList : Dictionary[BattleShipStats, Dictionary]

static func NewData(m : CardModule, TargetList : Dictionary[BattleShipStats, Dictionary]) -> OffensiveAnimationData:
	var data = OffensiveAnimationData.new()
	data.Mod = m
	data.DeffenceList = TargetList
	return data

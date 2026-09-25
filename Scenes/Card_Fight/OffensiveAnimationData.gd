extends AnimationData

class_name OffensiveAnimationData

var instigator : Node
var DeffenceList : Dictionary[BattleShipStats, Dictionary]

static func NewData(m : CardModule, Instigator : Node, TargetList : Dictionary[BattleShipStats, Dictionary]) -> OffensiveAnimationData:
	var data = OffensiveAnimationData.new()
	data.instigator = Instigator
	data.Mod = m
	data.DeffenceList = TargetList
	return data

extends Card_Passive

class_name OnDrawPassive

@export var ManualOnly : bool = false

func OnActionPerformed(data : Dictionary, _C : CardStats, PassiveOwner : BattleShipStats) -> PassiveAnimationData:
	if (ManualOnly and !data["ManualDraw"]):
		return null
	var actionReceiver : BattleShipStats = data["Receiver"]
	
	var possibleReceivers : Array[BattleShipStats] = GetPossibleReceivers(data, PassiveOwner)
	if (!possibleReceivers.has(actionReceiver)):
		return null
	
	var targets : Array[BattleShipStats] = GetPossibleTargets(data, PassiveOwner)
	
	if (targets.size() == 0):
		return null
	
	var dat : PassiveAnimationData = PassiveAnimationData.new()
	dat.Performer = data["Performer"]
	dat.Targets = targets

	return dat


func GetTrigger() -> ActionType:
	return ActionType.CARD_DRAW

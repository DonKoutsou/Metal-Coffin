extends Card_Passive

class_name OnTurnEndedPassive


func GetTrigger() -> ActionType:
	return ActionType.TURN_END

func OnActionPerformed(data : Dictionary, _C : CardStats, PassiveOwner : BattleShipStats) -> PassiveAnimationData:
	var actionPerformer : BattleShipStats = data["Performer"]
	
	var possiblePerformer : Array[BattleShipStats] = GetPossibleReceivers(data, PassiveOwner)
	if (!possiblePerformer.has(actionPerformer)):
		return null
	
	var targets : Array[BattleShipStats] = GetPossibleTargets(data, PassiveOwner)
	
	if (targets.size() == 0):
		return null
	
	var dat : PassiveAnimationData = PassiveAnimationData.new()
	dat.Performer = data["Performer"]
	dat.Targets = targets

	return dat

#------------------------------------------------------
func GetTrigerString() -> String:
	var triggerString : String = ActionType.keys()[GetTrigger()].replace("_", " ")
	var receiverString : String = ReceiverType.keys()[Receiver].replace("_", " ")
	
	return "[color=#ffc315]ON {1}'s {0}S[/color]".format([triggerString, receiverString])

extends Card_Passive

class_name OnFireTickPassive

#------------------------------------------------------
func GetTrigerString() -> String:
	var triggerString : String = ActionType.keys()[GetTrigger()].replace("_", " ")
	var receiverString : String = ReceiverType.keys()[Receiver].replace("_", " ")
	
	return "[color=#ffc315]ON {0}ED ON {1}[/color]".format([triggerString, receiverString])

func OnActionPerformed(data : Dictionary, _C : CardStats, PassiveOwner : BattleShipStats) -> PassiveAnimationData:
	var actionReceiver : BattleShipStats = data["Receiver"]
	
	var possibleReceivers : Array[BattleShipStats] = GetPossibleReceivers(data, PassiveOwner)
	if (!possibleReceivers.has(actionReceiver)):
		return null
	
	var targets : Array[BattleShipStats] = GetPossibleTargets(data, PassiveOwner)
	
	if (targets.size() == 0):
		return null
	
	var dat : PassiveAnimationData = PassiveAnimationData.new()
	dat.Performer = actionReceiver
	dat.Targets = targets

	return dat

#------------------------------------------------------
func GetPossibleReceivers(data : Dictionary, PassiveOwner : BattleShipStats) -> Array[BattleShipStats]:
	var actionReceiver : BattleShipStats = data["Receiver"]
	var sameTeam = actionReceiver.Friendly == PassiveOwner.Friendly
	
	var targets : Array[BattleShipStats] = []
	if (Receiver == ReceiverType.OWNER):
		targets.append(PassiveOwner)
		
	else: if (Receiver == ReceiverType.ANY_FRIENDLY):
		var friendly : Array[BattleShipStats]
		if (sameTeam):
			friendly = data["Friendly"].duplicate()
		else:
			friendly = data["Enemy"].duplicate()
		friendly.erase(PassiveOwner)
		targets.append_array(friendly)
		
	else: if (Receiver == ReceiverType.ANY_FRIENDLY_INCLUSIVE):
		if (sameTeam):
			targets.append_array(data["Friendly"])
		else:
			targets.append_array(data["Enemy"])
		
		
	else: if (Receiver == ReceiverType.ANY_ENEMY):
		if (sameTeam):
			targets.append_array(data["Enemy"])
		else:
			targets.append_array(data["Friendly"])

		
	else: if (Receiver == ReceiverType.ANY_SHIP):
		targets.append_array(data["Friendly"])
		targets.append_array(data["Enemy"])
		
	return targets

func GetTrigger() -> ActionType:
	return ActionType.FIRE_TICK

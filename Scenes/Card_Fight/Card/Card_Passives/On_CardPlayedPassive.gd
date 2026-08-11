extends Card_Passive

class_name OnCardPlayedPassive

func OnActionPerformed(data : Dictionary, _C : CardStats, PassiveOwner : BattleShipStats) -> PassiveAnimationData:
	var card : CardStats = data["Card"]
	if (card.OnPerformModule != null and card.OnPerformModule is not OffensiveCardModule):
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
	return ActionType.CARD_PLAYED


extends Card_Passive

class_name OnFirePassive

@export var AllowSelfDamage : bool = false

func GetTrigger() -> ActionType:
	return ActionType.FIRE_CAUSED

func OnActionPerformed(data : Dictionary, _C : CardStats, PassiveOwner : BattleShipStats) -> PassiveAnimationData:
	var actionReceiver : BattleShipStats = data["Receiver"]
	var Instigator : BattleShipStats = data["Performer"]
	
	if (!AllowSelfDamage and actionReceiver == Instigator):
		return null
		
	var possibleReceivers : Array[BattleShipStats] = GetPossibleReceivers(data, PassiveOwner)
	if (!possibleReceivers.has(actionReceiver)):
		return null
	
	var targets : Array[BattleShipStats] = GetPossibleTargets(data, PassiveOwner)
	
	var dat : PassiveAnimationData = PassiveAnimationData.new()
	dat.Performer = PassiveOwner
	dat.Targets = targets

	return dat

func GetTrigerString() -> String:
	var triggerString : String = ActionType.keys()[GetTrigger()].replace("_", " ")
	var receiverString : String = ReceiverType.keys()[Receiver].replace("_", " ")
	
	return "[color=#ffc315]ON {0}[/color] to [color=#ffc315]{1}[/color]".format([triggerString, receiverString])

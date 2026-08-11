extends OnDrawPassive

class_name OnDrawSpecificPassive

@export var CardType : CardStats.CardType

func OnActionPerformed(data : Dictionary, C : CardStats, PassiveOwner : BattleShipStats) -> PassiveAnimationData:
	if (C.Type != CardType):
		return null
		
	return super(data, C, PassiveOwner)

func GetTrigerString() -> String:
	var triggerString : String = ActionType.keys()[GetTrigger()].replace("_", " ")
	var receiverString : String = ReceiverType.keys()[Receiver].replace("_", " ")
	
	return "[color=#ffc315]ON {2} {0} BY {1}[/color]".format([triggerString, receiverString, CardStats.CardType.keys()[CardType]])

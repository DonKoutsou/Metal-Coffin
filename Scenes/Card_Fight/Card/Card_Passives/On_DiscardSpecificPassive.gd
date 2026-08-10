extends OnDiscardPassive

class_name OnDiscardSpecificPassive

@export var CardType : CardStats.CardType

func OnActionPerformed(data : Dictionary, C : CardStats, PassiveOwner : BattleShipStats) -> PassiveAnimationData:
	if (C.Type != CardType):
		return null
		
	return super(data, C, PassiveOwner)

func GetDesc(Tier : int) -> String:
	var st : String = ActionType.keys()[PassiveTrigger]
	return "[color=#ffc315]ON {1} {0}[/color]\n{1}".format([st.replace("_", " "),Module.GetDesc(Tier), CardStats.CardType.keys()[CardType]])

extends ConditionLeaf

class_name MissileCarrierInPositionCondition

func tick(actor: Node, blackboard: Blackboard) -> int:
	var Command = actor as Commander
	
	var Carrier = Command.FindMissileCarrierAbleToFireToPosition(Command.KnownEnemies[0])
	
	if (Carrier != null):
		blackboard.set_value("MissileCarrier", Carrier)
		return SUCCESS
	
	return FAILURE

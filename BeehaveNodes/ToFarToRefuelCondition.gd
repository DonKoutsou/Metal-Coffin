extends ConditionLeaf

class_name ToFarToRefuelCondition

func tick(actor: Node, blackboard: Blackboard) -> int:
	var MainShip = actor as HostileShip

	if (MainShip.ToFarFromRefuel()):
		return SUCCESS
	
	return FAILURE

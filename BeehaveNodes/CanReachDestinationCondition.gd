extends ConditionLeaf

class_name UnableToReachDestinationCondition

func tick(actor: Node, blackboard: Blackboard) -> int:
	var MainShip = actor as HostileShip

	if (!MainShip.CanReachDestination()):
		return SUCCESS
	
	return FAILURE

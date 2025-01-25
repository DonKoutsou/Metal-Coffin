extends ConditionLeaf

class_name UnableToReachDestinationCondition

func tick(actor: Node, _blackboard: Blackboard) -> int:
	var MainShip = actor as HostileShip
	
	var dist = MainShip.GetFuelRange()
	var actualdistance = MainShip.global_position.distance_to(MainShip.GetCurrentDestination())
	
	if (dist < actualdistance):
		return SUCCESS
	
	return FAILURE

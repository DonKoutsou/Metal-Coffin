@tool
extends ConditionLeaf

class_name UnableToReachDestinationCondition

func tick(actor: Node, _blackboard: Blackboard) -> int:
	var MainShip = actor as HostileShip
	
	var dist = MainShip.GetFuelRange()
	var actualdistance = MainShip.global_position.distance_squared_to(MainShip.GetCurrentDestination())
	
	if (dist * dist < actualdistance):
		print(MainShip.ShipName + " is unable to reach destination")
		return SUCCESS
	
	return FAILURE

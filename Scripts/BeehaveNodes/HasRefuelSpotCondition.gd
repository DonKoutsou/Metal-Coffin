@tool
extends ConditionLeaf

class_name HasRefuelSpotCondition

func tick(actor: Node, _blackboard: Blackboard) -> int:
	var Ship = actor as HostileShip
	if (Ship.RefuelSpot != null):
		return SUCCESS
	
	return FAILURE

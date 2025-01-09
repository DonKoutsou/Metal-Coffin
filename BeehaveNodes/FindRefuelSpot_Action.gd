@tool
extends ActionLeaf

class_name FindRefuelSpotAction

func tick(actor: Node, blackboard: Blackboard) -> int:
	
	var ship = actor as HostileShip
	
	var found = ship.FindRefuelSpot()
	if (found):
		return SUCCESS
	else:
		return FAILURE

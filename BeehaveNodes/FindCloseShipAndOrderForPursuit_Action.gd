@tool
extends ActionLeaf

class_name FindCloseShipAndOrderForPursuit_Action

func tick(actor: Node, blackboard: Blackboard) -> int:
	var Command = actor as Commander
	var ShipToPursue : MapShip = blackboard.get_value("ShipToPursuit")
	
	var closestship = Command.FindClosestFleetToPosition(ShipToPursue.global_position, true, true)
	if (closestship == null):
		return FAILURE
	Command.OrderShipToPursue(closestship, ShipToPursue)
	
	return SUCCESS

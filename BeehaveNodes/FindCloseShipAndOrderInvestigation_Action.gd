@tool
extends ActionLeaf

class_name FindCloseShipAndOrderInvestigation_Action

func tick(actor: Node, blackboard: Blackboard) -> int:
	var Command = actor as Commander
	
	var SignalInfo = blackboard.get_value("SignalToInvestigate")

	var closestship = Command.FindClosestFleetToPosition(SignalInfo[1], true, true)
	
	if (closestship == null):
		return RUNNING
		
	Command.OrderShipToInvestigate(closestship, SignalInfo[1], SignalInfo[0])
	
	return SUCCESS

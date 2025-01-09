@tool
extends ActionLeaf

class_name AtackAction

func tick(actor: Node, blackboard: Blackboard) -> int:
	var Command = actor as Commander

	var MissileCarrier = blackboard.get_value("MissileCarrier")
	
	var Target = Command.KnownEnemies.keys()[0]
	
	Command.OrderShipToAtack(MissileCarrier, Target)
	
	return SUCCESS

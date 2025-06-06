@tool
extends ConditionLeaf

class_name UnhandledEnemiesCondition

func tick(actor: Node, blackboard: Blackboard) -> int:
	var Command = actor as Commander
	for g : PlayerDrivenShip in Command.KnownEnemies:
		if (!g.Docked and !Command.IsShipBeingPursued(g)):
			blackboard.set_value("ShipToPursuit", g)
			return SUCCESS
	return FAILURE

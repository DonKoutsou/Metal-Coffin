extends ConditionLeaf

class_name HasKnownEnemiesCondition

func tick(actor: Node, _blackboard: Blackboard) -> int:
	var Command = actor as Commander
	if (Command.KnownEnemies.size() > 0):
		return SUCCESS
	
	return FAILURE

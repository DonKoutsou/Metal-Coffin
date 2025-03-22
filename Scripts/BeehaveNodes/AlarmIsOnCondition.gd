@tool
extends ConditionLeaf

class_name AlarmIsOnCondition

func tick(actor: Node, _blackboard: Blackboard) -> int:
	var Command = Commander.GetInstance()
	if (Command.Alarmed):
		return SUCCESS
	
	return FAILURE

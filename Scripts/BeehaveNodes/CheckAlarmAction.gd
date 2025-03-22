@tool
extends ActionLeaf

class_name CheckAlarmAction

func tick(actor: Node, blackboard: Blackboard) -> int:
	var Command = actor as Commander

	Command.CheckAlarm()
	
	return SUCCESS

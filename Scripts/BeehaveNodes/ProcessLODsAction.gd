@tool
extends ActionLeaf

class_name ProcessLODs

func tick(actor: Node, blackboard: Blackboard) -> int:
	var Command = actor as Commander

	Command.ProcessLODList()
	
	return SUCCESS

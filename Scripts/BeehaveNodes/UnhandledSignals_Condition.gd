@tool
extends ConditionLeaf

class_name UnhandledSignalsCondition

func tick(actor: Node, blackboard: Blackboard) -> int:
	var Command = actor as Commander
	for g in Command.EnemyPositionsToInvestigate.size():
		var investigatedship = Command.EnemyPositionsToInvestigate.keys()[g]
		var investigatedpos = Command.EnemyPositionsToInvestigate.values()[g]
		if (!Command.IsShipsPositionUnderInvestigation(investigatedship)):
			var SignalInfo = [investigatedship, investigatedpos]
			blackboard.set_value("SignalToInvestigate", SignalInfo)
			return SUCCESS
	return FAILURE

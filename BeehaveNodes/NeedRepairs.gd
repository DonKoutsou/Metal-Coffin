extends ConditionLeaf

class_name NeedRepairCondition

func tick(actor: Node, blackboard: Blackboard) -> int:
	var MainShip = actor as HostileShip

	var MaxHull = MainShip.Cpt.GetStatFinalValue("HULL")
	var Hull = MainShip.Cpt.GetStatCurrentValue("HULL")
	if (MaxHull/3 > Hull):
		return SUCCESS
	#var DistanceToDestination = global_position.distance_to(GetCurrentDestination())
	for g in MainShip.GetDroneDock().DockedDrones:
		var Ship = g as HostileShip
		MaxHull += Ship.Cpt.GetStatFinalValue("HULL")
		Hull += Ship.Cpt.GetStatCurrentValue("HULL")
	
	#take the average of to see if condition of all fleet is bad
	var FleetSize = MainShip.GetDroneDock().DockedDrones.size() + 1
	MaxHull /= FleetSize
	Hull /= FleetSize
	if (MaxHull/3 > Hull):
		return SUCCESS
	
	return FAILURE

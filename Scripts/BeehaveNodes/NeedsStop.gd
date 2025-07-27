@tool
extends ConditionLeaf

class_name NeedStopCondition

func tick(actor: Node, _blackboard: Blackboard) -> int:
	var MainShip = actor as HostileShip
	
	var dist = MainShip.GetFuelRange()
	var actualdistance = MainShip.global_position.distance_squared_to(MainShip.GetCurrentDestination())
	
	if (dist * dist < actualdistance):
		print(MainShip.ShipName + " is unable to reach destination")
		return SUCCESS
	
	var MaxHull = MainShip.Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL)
	var Hull = MainShip.Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL)
	if (MaxHull/3 > Hull):
		print(MainShip.ShipName + " needs repairs")
		return SUCCESS
	#var DistanceToDestination = global_position.distance_to(GetCurrentDestination())
	for g : HostileShip in MainShip.GetDroneDock().DockedDrones:
		MaxHull += g.Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL)
		Hull += g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL)
	
	#take the average of to see if condition of all fleet is bad
	var FleetSize = MainShip.GetDroneDock().DockedDrones.size() + 1
	MaxHull /= FleetSize
	Hull /= FleetSize
	if (MaxHull/3 > Hull):
		print(MainShip.ShipName + " needs repairs")
		return SUCCESS

	return FAILURE

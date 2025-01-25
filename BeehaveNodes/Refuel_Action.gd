@tool
extends ActionLeaf

class_name RefuelAction

func tick(actor: Node, _blackboard: Blackboard) -> int:
	var MainShip = actor as HostileShip
	#if (MainShip.Docked):
		#return SUCCESS
	var SimulationSpeed = MainShip.SimulationSpeed
	MainShip.Cpt.RefillResource(STAT_CONST.STATS.FUEL_TANK, 0.05 * SimulationSpeed)
	MainShip.Cpt.RefillResource(STAT_CONST.STATS.HULL, 0.02 * SimulationSpeed)
	
	for g in MainShip.GetDroneDock().DockedDrones:
		g.Cpt.RefillResource(STAT_CONST.STATS.FUEL_TANK, 0.05 * SimulationSpeed)
		MainShip.Cpt.RefillResource(STAT_CONST.STATS.HULL, 0.02 * SimulationSpeed)
	
	if (!MainShip.IsFuelFull() or MainShip.IsDamaged()):
		return RUNNING
	
	#Ship.SetSpeed(0)
	MainShip.RefuelSpot = null
	return SUCCESS

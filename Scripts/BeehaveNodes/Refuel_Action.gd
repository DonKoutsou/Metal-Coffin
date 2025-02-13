@tool
extends ActionLeaf

class_name RefuelAction

func tick(actor: Node, _blackboard: Blackboard) -> int:
	var MainShip = actor as HostileShip
	#if (MainShip.Docked):
		#return SUCCESS
	var SimulationSpeed = MainShip.SimulationSpeed
	var TickRate = _blackboard.get_value("TickRate")
	var RefuelSpeed = 0.05 * SimulationSpeed * TickRate
	var RepairSpeed = 0.02 * SimulationSpeed * TickRate
	MainShip.Cpt.RefillResource(STAT_CONST.STATS.FUEL_TANK, RefuelSpeed)
	MainShip.Cpt.RefillResource(STAT_CONST.STATS.HULL, RepairSpeed)
	
	for g in MainShip.GetDroneDock().DockedDrones:
		g.Cpt.RefillResource(STAT_CONST.STATS.FUEL_TANK, RefuelSpeed)
		MainShip.Cpt.RefillResource(STAT_CONST.STATS.HULL, RepairSpeed)
	
	if (!MainShip.IsFuelFull() or MainShip.IsDamaged()):
		return RUNNING
	
	#Ship.SetSpeed(0)
	MainShip.RefuelSpot = null
	return SUCCESS

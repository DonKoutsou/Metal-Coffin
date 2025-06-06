@tool
extends ActionLeaf

class_name RefuelAction

func tick(actor: Node, _blackboard: Blackboard) -> int:
	var MainShip = actor as HostileShip
	#if (MainShip.Docked):
		#return SUCCESS
	var SimulationSpeed = SimulationManager.SimSpeed()
	var TickRate = _blackboard.get_value("TickRate")
	var RefuelSpeed = 0.2 * SimulationSpeed * TickRate
	var RepairSpeed = 0.04 * SimulationSpeed * TickRate
	var ReloadSpeed = 0.01 * SimulationSpeed * TickRate
	MainShip.Cpt.RefillResource(STAT_CONST.STATS.FUEL_TANK, RefuelSpeed)
	MainShip.Cpt.RefillResource(STAT_CONST.STATS.HULL, RepairSpeed)
	MainShip.Cpt.RefillResource(STAT_CONST.STATS.MISSILE_SPACE, ReloadSpeed)
	for g in MainShip.GetDroneDock().DockedDrones:
		g.Cpt.RefillResource(STAT_CONST.STATS.FUEL_TANK, RefuelSpeed)
		g.Cpt.RefillResource(STAT_CONST.STATS.HULL, RepairSpeed)
		g.Cpt.RefillResource(STAT_CONST.STATS.MISSILE_SPACE, ReloadSpeed)
	if (!MainShip.IsFuelFull() or MainShip.IsDamaged() or MainShip.NeedsReload()):
		return RUNNING
	
	#Ship.SetSpeed(0)
	MainShip.RefuelSpot = null
	return SUCCESS

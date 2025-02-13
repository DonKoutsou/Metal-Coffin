@tool
extends ActionLeaf

class_name AproachRefuelSpotAction

func tick(actor: Node, _blackboard: Blackboard) -> int:
	var MainShip = actor as HostileShip
	
	#if (Ship.Docked):
		#var CommandPos = Ship.Command.global_position
		#var CommandDestinationPos = Ship.Command.RefuelSpot.global_position
		#if (CommandPos.distance_to(CommandDestinationPos) > 1):
			#return RUNNING
		#return SUCCESS
	
	var Pos = MainShip.global_position
	var SimulationSpeed = MainShip.SimulationSpeed
	var TickRate = _blackboard.get_value("TickRate")
	var DestinationPos = MainShip.RefuelSpot.global_position

	if (Pos.distance_to(DestinationPos) > 1):
		for g in MainShip.GetDroneDock().DockedDrones:
			var Ship = g as HostileShip
			
			var dronefuel = (MainShip.GetShipSpeed() / 10 / Ship.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY)) * SimulationSpeed * TickRate
			if (Ship.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) > dronefuel):
				Ship.Cpt.ConsumeResource(STAT_CONST.STATS.FUEL_TANK, dronefuel)
			else : if (MainShip.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) >= dronefuel):
				MainShip.Cpt.ConsumeResource(STAT_CONST.STATS.FUEL_TANK, dronefuel)
		
		var ftoconsume = MainShip.GetShipSpeed() / 10 / MainShip.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY) * SimulationSpeed * TickRate
		if (MainShip.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) > ftoconsume):
			MainShip.Cpt.ConsumeResource(STAT_CONST.STATS.FUEL_TANK, ftoconsume)
		else: if (MainShip.GetDroneDock().DronesHaveFuel(ftoconsume)):
			MainShip.GetDroneDock().SyphonFuelFromDrones(ftoconsume)
			
		MainShip.SetSpeed(MainShip.GetShipMaxSpeed())
		#var SimulationSpeed = Ship.SimulationSpeed
		MainShip.global_position += MainShip.GetShipSpeedVec() * SimulationSpeed * TickRate
		MainShip.ShipLookAt(DestinationPos)
		return RUNNING
	
	MainShip.SetSpeed(0)
	return SUCCESS

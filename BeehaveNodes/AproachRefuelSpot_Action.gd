@tool
extends ActionLeaf

class_name AproachRefuelSpotAction

func tick(actor: Node, blackboard: Blackboard) -> int:
	var MainShip = actor as HostileShip
	
	#if (Ship.Docked):
		#var CommandPos = Ship.Command.global_position
		#var CommandDestinationPos = Ship.Command.RefuelSpot.global_position
		#if (CommandPos.distance_to(CommandDestinationPos) > 1):
			#return RUNNING
		#return SUCCESS
	
	var Pos = MainShip.global_position
	var SimulationSpeed = MainShip.SimulationSpeed
	var DestinationPos = MainShip.RefuelSpot.global_position

	if (Pos.distance_to(DestinationPos) > 1):
		for g in MainShip.GetDroneDock().DockedDrones:
			var Ship = g as HostileShip
			
			var dronefuel = (MainShip.GetShipSpeed() / 10 / Ship.Cpt.GetStatFinalValue("FUEL_EFFICIENCY")) * SimulationSpeed
			if (Ship.Cpt.GetStatCurrentValue("FUEL_TANK") > dronefuel):
				Ship.Cpt.GetStat("FUEL_TANK").ConsumeResource(dronefuel)
			else : if (MainShip.Cpt.GetStat("FUEL_TANK").GetCurrentValue() >= dronefuel):
				MainShip.Cpt.GetStat("FUEL_TANK").ConsumeResource(dronefuel)
		
		var ftoconsume = MainShip.GetShipSpeed() / 10 / MainShip.Cpt.GetStatFinalValue("FUEL_EFFICIENCY") * SimulationSpeed
		if (MainShip.Cpt.GetStatCurrentValue("FUEL_TANK") > ftoconsume):
			MainShip.Cpt.GetStat("FUEL_TANK").ConsumeResource(ftoconsume)
		else: if (MainShip.GetDroneDock().DronesHaveFuel(ftoconsume)):
			MainShip.GetDroneDock().SyphonFuelFromDrones(ftoconsume)
			
		MainShip.SetSpeed(MainShip.GetShipMaxSpeed())
		#var SimulationSpeed = Ship.SimulationSpeed
		MainShip.global_position += MainShip.GetShipSpeedVec() * SimulationSpeed
		MainShip.ShipLookAt(DestinationPos)
		return RUNNING
	
	MainShip.SetSpeed(0)
	return SUCCESS

@tool
extends ActionLeaf

class_name ApreachDestinationAction

func tick(actor: Node, blackboard: Blackboard) -> int:
	var MainShip = actor as HostileShip

	#if (MainShip.Docked):
		#var CommandPos = MainShip.Command.global_position
		#var CommandDestinationPos = MainShip.Command.GetCurrentDestination()
		#if (CommandPos.distance_to(CommandDestinationPos) > 1):
			#return RUNNING
		#return SUCCESS
	
	var SimulationSpeed = MainShip.SimulationSpeed
	var Pos = MainShip.global_position
	var DestinationPos = MainShip.GetCurrentDestination()
	
	if (Pos.distance_to(DestinationPos) > 1):
		for g in MainShip.GetDroneDock().DockedDrones:
			var Ship = g as HostileShip
			
			var dronefuel = (MainShip.GetShipSpeed() / 10 / Ship.Cpt.GetStatValue("FUEL_EFFICIENCY")) * SimulationSpeed
			if (Ship.Cpt.GetStatCurrentValue("FUEL_TANK") > dronefuel):
				Ship.Cpt.GetStat("FUEL_TANK").ConsumeResource(dronefuel)
			else : if (MainShip.Cpt.GetStat("FUEL_TANK").GetCurrentValue() >= dronefuel):
				MainShip.Cpt.GetStat("FUEL_TANK").ConsumeResource(dronefuel)
		
		var ftoconsume = MainShip.GetShipSpeed() / 10 / MainShip.Cpt.GetStatValue("FUEL_EFFICIENCY") * SimulationSpeed
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

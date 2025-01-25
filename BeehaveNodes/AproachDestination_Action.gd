@tool
extends ActionLeaf

class_name ApreachDestinationAction

func tick(actor: Node, _blackboard: Blackboard) -> int:
	var MainShip = actor as HostileShip

	
	var SimulationSpeed = MainShip.SimulationSpeed
	var Pos = MainShip.global_position
	var DestinationPos = MainShip.GetCurrentDestination()
	
	if (Pos.distance_to(DestinationPos) > 1):
		var Speed = MainShip.GetShipSpeed()
		var Cap = MainShip.Cpt
		
		var DroneD = MainShip.GetDroneDock() as HostileDroneDock
		for g in DroneD.DockedDrones:
			var Ship = g as HostileShip
			var DroneCap = Ship.Cpt
			var dronefuel = (Speed / 10 / Ship.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY)) * SimulationSpeed
			if (DroneCap.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) > dronefuel):
				DroneCap.ConsumeResource(STAT_CONST.STATS.FUEL_TANK ,dronefuel)
			else : if (Cap.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) >= dronefuel):
				Cap.ConsumeResource(STAT_CONST.STATS.FUEL_TANK, dronefuel)
		
		var ftoconsume = Speed / 10 / MainShip.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY) * SimulationSpeed
		if (Cap.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) > ftoconsume):
			Cap.ConsumeResource(STAT_CONST.STATS.FUEL_TANK, ftoconsume)
		else: if (DroneD.DronesHaveFuel(ftoconsume)):
			DroneD.SyphonFuelFromDrones(ftoconsume)
			
		MainShip.SetSpeed(MainShip.GetShipMaxSpeed())
		#var SimulationSpeed = Ship.SimulationSpeed
		MainShip.global_position += MainShip.GetShipSpeedVec() * SimulationSpeed
		MainShip.ShipLookAt(DestinationPos)
		return RUNNING
	
	MainShip.SetSpeed(0)
	return RUNNING

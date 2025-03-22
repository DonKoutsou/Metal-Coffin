@tool
extends ActionLeaf

class_name ApreachDestinationAction

func tick(actor: Node, _blackboard: Blackboard) -> int:
	var MainShip = actor as HostileShip
	var TickRate = _blackboard.get_value("TickRate")
	var SimulationSpeed = SimulationManager.SimSpeed()
	var Pos = MainShip.global_position
	var DestinationPos = MainShip.GetCurrentDestination()
	var MainShipMaxSpeed = MainShip.GetShipMaxSpeed()

	if (Pos.distance_to(DestinationPos) > 1):
		var Speed = MainShip.GetShipSpeed()
		var Cap = MainShip.Cpt
		var MainShipFuelReserves = Cap.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
		var FuelToConsume = 0
		
		var DroneD = MainShip.GetDroneDock() as HostileDroneDock
		for g in DroneD.DockedDrones:
			var Ship = g as HostileShip
			var DroneCap = Ship.Cpt
			var dronefuel = (Speed / DroneCap.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY)) * TickRate * SimulationSpeed
			if (DroneCap.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) > dronefuel):
				DroneCap.ConsumeResource(STAT_CONST.STATS.FUEL_TANK ,dronefuel)
			else : if (MainShipFuelReserves - FuelToConsume >= dronefuel):
				FuelToConsume += dronefuel
		
		FuelToConsume += Speed / MainShip.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY) * TickRate * SimulationSpeed
		if (MainShipFuelReserves - FuelToConsume > 0):
			Cap.ConsumeResource(STAT_CONST.STATS.FUEL_TANK, FuelToConsume)
		else: if (DroneD.DronesHaveFuel(FuelToConsume)):
			DroneD.SyphonFuelFromDrones(FuelToConsume)
			
		MainShip.SetSpeed(MainShipMaxSpeed)
		#var SimulationSpeed = Ship.SimulationSpeed
		MainShip.global_position += MainShip.GetShipSpeedVec() * TickRate * SimulationSpeed
		MainShip.ShipLookAt(DestinationPos)
		return SUCCESS
	
	MainShip.SetSpeed(0)
	return SUCCESS

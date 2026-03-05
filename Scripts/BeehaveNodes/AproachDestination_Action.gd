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

	if (Pos.distance_squared_to(DestinationPos) > 10):
		var Speed = MainShip.GetShipSpeed() / 360
		var Cap = MainShip.Cpt
		var MainShipFuelReserves = Cap.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
		var FuelToConsume = 0
		
		var DroneD = MainShip.GetDroneDock() as HostileDroneDock
		for g in DroneD.DockedDrones:
			var Ship = g as HostileShip
			var DroneCap = Ship.Cpt
			var droneWeight = DroneCap.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
			var droneEfficiency = (DroneCap.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY) / pow(droneWeight, 0.5)) * 10
			var DroneFuelConsumtion = Speed / droneEfficiency
			DroneFuelConsumtion *= SimulationManager.SimSpeed() * TickRate
			if (DroneCap.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) > DroneFuelConsumtion):
				DroneCap.ConsumeResource(STAT_CONST.STATS.FUEL_TANK ,DroneFuelConsumtion)
			else : if (MainShipFuelReserves - FuelToConsume >= DroneFuelConsumtion):
				FuelToConsume += DroneFuelConsumtion
		
		var ShipWeight = Cap.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
		var ShipEfficiency = (Cap.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY) / pow(ShipWeight, 0.5)) * 10
		var FuelConsumtion = Speed / ShipEfficiency
		FuelConsumtion *= SimulationManager.SimSpeed() * TickRate

		FuelToConsume += FuelConsumtion
		
		if (MainShipFuelReserves - FuelToConsume > 0):
			Cap.ConsumeResource(STAT_CONST.STATS.FUEL_TANK, FuelToConsume)
		else: if (DroneD.DronesHaveFuel(FuelToConsume)):
			DroneD.SyphonFuelFromDrones(FuelToConsume)
			
		MainShip.SetSpeed(MainShipMaxSpeed)
		
		var offset = MainShip.GetShipSpeedVec() * TickRate
		MainShip.LastRecordedOffset = offset
		
		MainShip.global_position += offset * SimulationSpeed
		
		var directiontoDestination = MainShip.global_position.direction_to(DestinationPos).angle()
		if (MainShip.rotation != directiontoDestination):
			MainShip.Steer(clamp((directiontoDestination - MainShip.rotation) * TickRate * SimulationSpeed, -0.01, 0.01))
		#MainShip.ShipLookAt(DestinationPos)
		return SUCCESS
	
	MainShip.SetSpeed(0)
	return SUCCESS

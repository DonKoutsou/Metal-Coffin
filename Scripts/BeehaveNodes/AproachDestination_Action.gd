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
		var Speed = MainShip.GetShipSpeed() / 360
		var Cap = MainShip.Cpt
		var MainShipFuelReserves = Cap.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
		var FuelToConsume = 0
		
		var DroneD = MainShip.GetDroneDock() as HostileDroneDock
		for g in DroneD.DockedDrones:
			var Ship = g as HostileShip
			var DroneCap = Ship.Cpt
			var DroneWeight = DroneCap.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
			var dronefuel = (Speed / (DroneCap.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY) - DroneWeight/40)) * TickRate * SimulationSpeed
			if (DroneCap.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) > dronefuel):
				DroneCap.ConsumeResource(STAT_CONST.STATS.FUEL_TANK ,dronefuel)
			else : if (MainShipFuelReserves - FuelToConsume >= dronefuel):
				FuelToConsume += dronefuel
		
		var Weight = MainShip.Cpt.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
		
		#var eff_eff = MainShip.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY) - (Weight / 40.0)
		#var ShipRange = roundi(50 * pow(FuelTank * (FuelEfficiency - (Weight / 40.0)), 0.55))
		
		FuelToConsume += pow(Speed / 50, 1 / 0.55) / (MainShip.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY) - (MainShip.Cpt.GetStatFinalValue(STAT_CONST.STATS.WEIGHT) / 40)) * TickRate * SimulationSpeed
		if (MainShipFuelReserves - FuelToConsume > 0):
			Cap.ConsumeResource(STAT_CONST.STATS.FUEL_TANK, FuelToConsume)
		else: if (DroneD.DronesHaveFuel(FuelToConsume)):
			DroneD.SyphonFuelFromDrones(FuelToConsume)
			
		MainShip.SetSpeed(MainShipMaxSpeed)
		#var SimulationSpeed = Ship.SimulationSpeed
		MainShip.global_position += MainShip.GetShipSpeedVec() * TickRate * SimulationSpeed
		var directiontoDestination = MainShip.global_position.direction_to(DestinationPos).angle()
		if (MainShip.rotation != directiontoDestination):
			MainShip.Steer(clamp((directiontoDestination - MainShip.rotation) * TickRate * SimulationSpeed, -0.01, 0.01))
		#MainShip.ShipLookAt(DestinationPos)
		return SUCCESS
	
	MainShip.SetSpeed(0)
	return SUCCESS

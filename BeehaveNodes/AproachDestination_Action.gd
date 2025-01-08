@tool
extends ActionLeaf

class_name ApreachDestinationAction

func tick(actor: Node, blackboard: Blackboard) -> int:
	var Ship = actor as HostileShip
	
	var Pos = Ship.global_position
	
	var DestinationPos = Ship.GetCurrentDestination()

	if (Pos.distance_to(DestinationPos) > 1):
		Ship.SetSpeed(Ship.GetShipMaxSpeed())
		var SimulationSpeed = Ship.SimulationSpeed
		Ship.global_position += Ship.GetShipSpeedVec() * SimulationSpeed
		Ship.ShipLookAt(DestinationPos)
		return RUNNING
	
	Ship.SetSpeed(0)
	return SUCCESS

@tool
extends ActionLeaf

class_name AproachRefuelSpotAction

func tick(actor: Node, blackboard: Blackboard) -> int:
	var Ship = actor as HostileShip
	
	#if (Ship.Docked):
		#var CommandPos = Ship.Command.global_position
		#var CommandDestinationPos = Ship.Command.RefuelSpot.global_position
		#if (CommandPos.distance_to(CommandDestinationPos) > 1):
			#return RUNNING
		#return SUCCESS
	
	var Pos = Ship.global_position
	
	var DestinationPos = Ship.RefuelSpot.global_position

	if (Pos.distance_to(DestinationPos) > 1):
		Ship.SetSpeed(Ship.GetShipMaxSpeed())
		var SimulationSpeed = Ship.SimulationSpeed
		Ship.global_position += Ship.GetShipSpeedVec() * SimulationSpeed
		Ship.ShipLookAt(DestinationPos)
		return RUNNING
	
	Ship.SetSpeed(0)
	return SUCCESS

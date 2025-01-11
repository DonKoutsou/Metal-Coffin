@tool
extends ActionLeaf

class_name FindRefuelSpotAction

func tick(actor: Node, blackboard: Blackboard) -> int:
	
	var ship = actor as HostileShip

	var dist = ship.GetFuelRange()
	
	var DistToSpot = 9999999999
	
	var RefuelSpot
	
	var DistanceToDestination = ship.global_position.distance_to(ship.GetCurrentDestination())
	for g in get_tree().get_nodes_in_group("EnemyDestinations"):
		var spot = g as MapSpot
		var D = spot.global_position.distance_to(ship.global_position)
		#if we cant reach it look for another
		if (D >= dist):
			continue
		
		if (D > DistToSpot):
			continue
		
		DistToSpot = D
		RefuelSpot = spot
		if (DistToSpot < 10):
			break
		
	if (RefuelSpot != null):
		print(ship.ShipName + " will take a detour through " + RefuelSpot.SpotInfo.SpotName + " to refuel")
		ship.RefuelSpot = RefuelSpot
		return SUCCESS
	else:
		print(ship.ShipName + " whas failed to find a refuel spot ")
		return FAILURE

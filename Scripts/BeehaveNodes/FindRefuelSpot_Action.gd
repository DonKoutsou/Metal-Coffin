@tool
extends ActionLeaf

class_name FindRefuelSpotAction

func tick(actor: Node, _blackboard: Blackboard) -> int:
	
	var Ship = actor as HostileShip
	if (Ship.RefuelSpot != null):
		print(Ship.ShipName + " already has refuel spot")
		return SUCCESS

	#var dist = Ship.GetFuelRange()
	
	var DistToSpot = 9999999999
	
	var RefuelSpot
	
	#var DistanceToDestination = ship.global_position.distance_to(ship.GetCurrentDestination())
	for g in get_tree().get_nodes_in_group("EnemyDestinations"):
		var spot = g as MapSpot
		var D = spot.global_position.distance_to(Ship.global_position)
		#if we cant reach it look for another
		#if (D >= dist):
			#continue
		
		if (D > DistToSpot):
			continue
		
		DistToSpot = D
		RefuelSpot = spot
		if (DistToSpot < 10):
			break
		
	if (RefuelSpot != null):
		print(Ship.ShipName + " will take a detour through " + RefuelSpot.SpotInfo.SpotName + " to refuel")
		Ship.RefuelSpot = RefuelSpot
		return SUCCESS
	else:
		print(Ship.ShipName + " whas failed to find a refuel spot ")
		return FAILURE

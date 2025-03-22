@tool
extends ActionLeaf

class_name FindRefugeAction

func tick(actor: Node, _blackboard: Blackboard) -> int:
	
	var ship = actor as HostileShip

	var dist = ship.GetFuelRange()
	
	var DistToSpot = 9999999999
	
	var RefugeSpot
	
	#var DistanceToDestination = ship.global_position.distance_to(ship.GetCurrentDestination())
	for g in get_tree().get_nodes_in_group("EnemyDestinations"):
		var spot = g as MapSpot
		var D = spot.global_position.distance_to(ship.global_position)
		#if we cant reach it look for another
		if (D >= dist):
			continue
		
		if (D > DistToSpot):
			continue
		
		DistToSpot = D
		RefugeSpot = spot
		if (DistToSpot < 10):
			break
		
	if (RefugeSpot != null):
		print(ship.ShipName + " will take a refuge at " + RefugeSpot.SpotInfo.SpotName + " until the alarm goese off")
		ship.RefugeSpot = RefugeSpot
		return SUCCESS
	else:
		print(ship.ShipName + " whas failed to find a refuge spot ")
		return FAILURE

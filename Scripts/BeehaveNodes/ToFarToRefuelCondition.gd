extends ConditionLeaf

class_name ToFarToRefuelCondition

func tick(actor: Node, _blackboard: Blackboard) -> int:
	var MainShip = actor as HostileShip

	var dist = MainShip.GetFuelRange()
	#var DistanceToDestination = global_position.distance_to(GetCurrentDestination())
	for g in get_tree().get_nodes_in_group("EnemyDestinations"):
		var spot = g as MapSpot
		if (spot.global_position.distance_squared_to(MainShip.global_position) < dist * dist):
			return FAILURE
			
	print(MainShip.ShipName + " is too far from reafuel stations")
	
	return SUCCESS

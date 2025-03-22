@tool
extends ConditionLeaf

class_name ShouldNotSimulate

func tick(actor: Node, _blackboard: Blackboard) -> int:
	var PlayerShips = get_tree().get_nodes_in_group("PlayerShips")
	
	var MainShipPos : Vector2 = actor.global_position
	
	for g in PlayerShips:
		if (MainShipPos.distance_to(g.global_position) > 10000):
			return SUCCESS

	return FAILURE

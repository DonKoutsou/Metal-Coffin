extends Happening_Option
class_name Recruit_Locator_Happening_Option

func OptionResault(EventOrigin : MapSpot) -> String:
	var ClosestRecruitLoc = FindClosestRecruit(EventOrigin)
	if (ClosestRecruitLoc == Vector2.ZERO):
		return "There are not possible rebels in any of the nearby towns as far as i know."
	var Dir = Helper.GetInstance().AngleToDirection(EventOrigin.global_position.angle_to_point(ClosestRecruitLoc))
	var Dist = Helper.GetInstance().DistanceToDistance(EventOrigin.global_position.distance_to(ClosestRecruitLoc))
	
	return "I know of a fleet nearby who's been looking to joint the rebelion, the are {0} to the {1}.".format([Dist, Dir])

func FindClosestRecruit(EventOrigin : MapSpot) -> Vector2:
	var RecruitLocations =  EventOrigin.get_tree().get_nodes_in_group("CrewRecruitTown")
	
	var ClosestLoc : MapSpot
	var ClosestDist : float = 999999999999999
	
	for g : MapSpot in RecruitLocations:
		if (g == EventOrigin):
			continue
		if (g.Visited):
			continue
		var dist = g.global_position.distance_to(EventOrigin.global_position)
		if (dist < ClosestDist):
			ClosestDist = dist
			ClosestLoc = g
		
	if (ClosestDist < 10000):
		return ClosestLoc.global_position
	
	return Vector2.ZERO

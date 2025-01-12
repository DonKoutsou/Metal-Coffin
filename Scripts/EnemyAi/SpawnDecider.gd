extends Resource

class_name SpawnDecider

@export var CaptainList : Array[CaptainSpawnInfo]

var sorted_captain_list

func Init() -> void:
	# Sort CaptainList by cost descending to prioritize more powerful ships
	sorted_captain_list = CaptainList.duplicate()
	sorted_captain_list.sort_custom(SortByCostDescending)

func GetSpawnsForLocation(YPos : float) -> Array[Captain]:
	var time = Time.get_ticks_msec()
	
	var Fleet : Array[Captain] = []
	var Points = GetPointsForPosition(abs(YPos))
	var CptnInfo = generate_fleet(Points)
	for g in CptnInfo:
		var cpt = Captain.new()
		cpt.CopyStats(g.Cpt)
		Fleet.append(cpt)
	print("Generating fleet took " + var_to_str(Time.get_ticks_msec() - time) + " msec")
	return Fleet

func GetPointsForPosition(YPos : float) -> int:
	return roundi(max(50, YPos / 100))

func generate_fleet(points: int) -> Array[CaptainSpawnInfo]:
	var fleet : Array[CaptainSpawnInfo] = []

	# Iterate over the sorted list and fill the fleet
	for ship in sorted_captain_list:
		var CInfo = ship as CaptainSpawnInfo
		var max_ships = min(points / CInfo.Cost, CInfo.MaxAmmInFleet)

		# Add the ships to the fleet if budget allows
		for i in range(max_ships):  # Use a simple loop variable like 'i'
			if points >= CInfo.Cost and fleet.size() < 6:
				fleet.append(CInfo)
				points -= CInfo.Cost
			else:
				break
	
	return fleet

# Custom sort function: Sort by cost descending
static func SortByCostDescending(a :CaptainSpawnInfo, b : CaptainSpawnInfo):
	return b.Cost - a.Cost

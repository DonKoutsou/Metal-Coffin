extends Resource

class_name SpawnDecider

@export var CaptainList : Array[CaptainSpawnInfo]
@export var GroundUnits : Array[CaptainSpawnInfo]

@export var MerchList : Array[MerchandiseInfo]

const LowestPrice : int = 50
const MerchLowest : int = 2
var sorted_captain_list
var sorted_ground_captain_list

func Init() -> void:
	# Sort CaptainList by cost descending to prioritize more powerful ships
	sorted_captain_list = CaptainList.duplicate()
	sorted_ground_captain_list = GroundUnits.duplicate()
	sorted_captain_list.sort_custom(SortByCostDescending)
	sorted_ground_captain_list.sort_custom(SortByCostDescending)
	
func GetMerchForPosition(YPos: float) -> Array[Merchandise]:
	var available_merch: Array[Merchandise] = []
	var points = GetPointsForPosition(abs(YPos))

	# Iterate through the MerchList to select merchandise based on points
	while points > MerchLowest:
		var m = MerchList.pick_random() as MerchandiseInfo
		if (points > m.Cost):
			var hasm = false
			for g in available_merch:
				if (m.Merch.It == g.It):
					g.Amm += 1
					hasm = true
					break
			if (!hasm):
				var NewMerch = m.Merch.duplicate(false)
				NewMerch.Amm = 1
				available_merch.append(NewMerch)
			points -= m.Cost
	return available_merch

func GetSpawnsForLocation(YPos : float, Patrol : bool, stage : Happening.GameStage) -> Array[Captain]:
	#var time = Time.get_ticks_msec()
	
	var Fleet : Array[Captain] = []
	var Points = GetPointsForPosition(abs(YPos))

	var CptnInfo = generate_fleet(Points, Patrol, stage)
	for g in CptnInfo:
		var cpt = Captain.new()
		cpt.call_deferred("CopyStats", g.Cpt)
		Fleet.append(cpt)
	#print("Generating fleet took " + var_to_str(Time.get_ticks_msec() - time) + " msec")
	#var FleetNames = "Fleet : "
	#for g in Fleet:
		#FleetNames += "\n" + g.ShipCallsign
	#print(FleetNames)
	return Fleet

func GetPointsForPosition(YPos : float) -> int:
	return roundi(max(50, YPos / 100))

func generate_fleet(points: int, Patrol : bool, stage : Happening.GameStage) -> Array[CaptainSpawnInfo]:
	var fleet : Array[CaptainSpawnInfo] = []
	var available_ships: Array = sorted_captain_list.duplicate()
	if (Patrol):
		points *= 3
	else:
		available_ships.append_array(sorted_ground_captain_list.duplicate())
	# Randomly shuffle the available ships to introduce variability in selection.
	#available_ships.shuffle()
	
	# While there's space in the fleet, try to maximize the points usage
	# with a dynamic strategy.
	while fleet.size() < 7 and points >= LowestPrice:
		available_ships.shuffle()
		
		var selected_ship: CaptainSpawnInfo = null
		#var best_value = 0

		# Consider each ship for inclusion
		for ship in available_ships:
			var ship_info = ship as CaptainSpawnInfo
			
			if (ship_info.DontGenerateBefore > stage):
				continue
			if (fleet.size() == 0 and !ship_info.SpawnAlone):
				continue
			# Calculate how many we can afford and consider its strategic value
			var max_ships = min(points / ship_info.Cost, ship_info.MaxAmmInFleet - fleet.count(ship_info))
			if max_ships > 0:
				
				selected_ship = ship_info
				break
				## Calculate ship value by some heuristic (e.g., cost efficiency)
				#var value = ship_info.Cost  # Add your strategy metric here
				#
				## Decide if this ship is worth adding to the fleet
				#if value > best_value:
					#best_value = value
					#selected_ship = ship_info

		# If a valid ship is selected, add to the fleet
		if selected_ship:
			#var to_add = min(points / selected_ship.Cost, selected_ship.MaxAmmInFleet, 7 - fleet.size())
			#for i in range(to_add):
			if points >= selected_ship.Cost:
				fleet.append(selected_ship)
				points -= selected_ship.Cost
			#else:
				#break

	return fleet

# Custom sort function: Sort by cost descending
static func SortByCostDescending(a :CaptainSpawnInfo, b : CaptainSpawnInfo):
	return b.Cost - a.Cost

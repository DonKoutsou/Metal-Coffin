@tool
extends Resource

class_name SpawnDecider

@export_file("*.tres") var CaptainFileList : Array[String]
@export_file("*.tres") var GroundUnitFileList : Array[String]
@export_file("*.tres") var ConvoyUnitFileList : Array[String]
@export_file("*.tres") var RecruitFileList : Array[String]

@export_file("*.tres") var MerchFileList : Array[String]
@export_file("*.tres") var WorkshopFileList : Array[String]

const LowestPrice : int = 50
const MerchLowest : int = 2
const RECRUIT_LOWEST : int = 25

var sorted_captain_list : Array[CaptainSpawnInfo] = []
var sorted_ground_captain_list : Array[CaptainSpawnInfo] = []
var sorted_convoy_captain_list : Array[CaptainSpawnInfo] = []

@export_tool_button("Refresh") var RefreshAction = RefrshExistingItems 

#------------------------------------------------------------------------
func RefrshExistingItems() -> void:
	#WorkshopList.clear()
	#MerchList.clear()
	MerchFileList.clear()
	WorkshopFileList.clear()
	if (!Engine.is_editor_hint()):
		return
	var DirsToExplore : PackedStringArray = ["res://Resources/Items"]
	for g in DirsToExplore:
		var dir = DirAccess.open(g)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					print("Found directory: " + file_name)
					DirsToExplore.append(g + "/" + file_name)
				else:
					print("Found file: " + file_name)
					var It = load(g + "/" + file_name)
					AddMerchToLists(It, file_name)
					
				file_name = dir.get_next()

#------------------------------------------------------------------------
func AddMerchToLists(It : Item, FileName :String) -> void:
	if (!FileAccess.file_exists("res://Resources/Merch/" + FileName)):
		var MerInfo = MerchandiseInfo.new()
		#var Mer = Merchandise.new()
		#MerInfo.Merch = Mer
		#Mer.It = It
		MerInfo.It = It.resource_path
		#ResourceSaver.save(Mer, "res://Resources/Merch/" + "M_" +FileName)
		ResourceSaver.save(MerInfo, "res://Resources/Merch/" + FileName)
		#MerInfo.Merch = ResourceLoader.load("res://Resources/Merch/" + "M_" +FileName)
		
	if (It is ShipPart):
		#var merchInfo : MerchandiseInfo = ResourceLoader.load("res://Resources/Merch/" + FileName)
		#if (!FileAccess.file_exists(merchInfo.Merch.resource_path)):
			#ResourceSaver.save(merchInfo.Merch, "res://Resources/Merch/" + "M_" +FileName)
		#merchInfo.Merch = ResourceLoader.load("res://Resources/Merch/" + "M_" +FileName)
		#merchInfo.It = merchInfo.Merch.It.resource_path
		WorkshopFileList.append("res://Resources/Merch/" + FileName)
		#ResourceSaver.save(merchInfo, "res://Resources/Merch/" + FileName)
	else:
		#var merchInfo : MerchandiseInfo = ResourceLoader.load("res://Resources/Merch/" + FileName)
		#if (!FileAccess.file_exists(merchInfo.Merch.resource_path)):
		#	ResourceSaver.save(merchInfo.Merch, "res://Resources/Merch/" + "M_" +FileName)
		#merchInfo.Merch = ResourceLoader.load("res://Resources/Merch/" + "M_" +FileName)
		#merchInfo.It = merchInfo.Merch.It.resource_path
		MerchFileList.append("res://Resources/Merch/" + FileName)
		#ResourceSaver.save(merchInfo, "res://Resources/Merch/" + FileName)

func LoadAndSort() -> void:
	# Sort CaptainList by cost descending to prioritize more powerful ships
	
	sorted_captain_list.clear()
	for file in CaptainFileList:
		sorted_captain_list.append(ResourceLoader.load(file))
	sorted_captain_list.sort_custom(SortByCostDescending)
	
	sorted_ground_captain_list.clear()
	for file in GroundUnitFileList:
		sorted_ground_captain_list.append(ResourceLoader.load(file))
	sorted_ground_captain_list.sort_custom(SortByCostDescending)
	
	sorted_convoy_captain_list.clear()
	for file in ConvoyUnitFileList:
		sorted_convoy_captain_list.append(ResourceLoader.load(file))
	sorted_convoy_captain_list.sort_custom(SortByCostDescending)
	
func Unload() -> void:
	sorted_captain_list.clear()
	sorted_ground_captain_list.clear()
	sorted_convoy_captain_list.clear()

func Init() -> void:
	LoadAndSort()
	
#------------------------------------------------------------------------
#Returns a dictonary containing the filepath to the item as key and the ammount in the value
func GetMerchForPosition(YPos: float, HasUp : bool, capital : bool) -> Dictionary[String, int]:
	var available_merch: Dictionary[String, int] = {}
	var points = GetMerchPointsForPosition(abs(YPos))
	var stage = Happening.GetStageForYPos(YPos)
	
	if (capital):
		points *= 1.5
	if (HasUp):
		points *= 2
		stage = min(stage + 1, Happening.GameStage.size() - 1)
		
	# Iterate through the MerchList to select merchandise based on points
	while points > MerchLowest:
		var randomIndex = Rand.InstanceRandom.RandIRange(0, MerchFileList.size() - 1) 
		var m : MerchandiseInfo = ResourceLoader.load(MerchFileList[randomIndex])
		if (m.DontGenerateBefore > stage):
				continue
				
		var it : String
		
		for itFile : String in available_merch:
			if (m.It == itFile):
				it = itFile
				break
		
		if (points > m.Cost):
			if (!it.is_empty()):
				available_merch[it] += 1
			else:
				available_merch[m.It] = 1
	
			points -= m.Cost
	return available_merch
	
#------------------------------------------------------------------------
func GetRecruitsForPosition(YPos: float, _HasRec : bool, capital : bool) -> Array[Captain]:
	var available_Recruits : Array[Captain] = []
	var points = GetRecruitPointsForPosition(abs(YPos))
	if (capital):
		points *= 1.5
		
	#print("Picking recruits for pos {0} with points {1}".format([YPos, points]))
	var stage = Happening.GetStageForYPos(YPos)
	var recs = RecruitFileList.duplicate()
	
	# Iterate through the MerchList to select merchandise based on points
	while points > RECRUIT_LOWEST and recs.size() > 0:
		var randomIndex = Rand.InstanceRandom.RandIRange(0, recs.size() - 1)
		var RandomRec : CaptainSpawnInfo = ResourceLoader.load(recs[randomIndex])
		
		if (RandomRec.DontGenerateBefore > stage):
			continue
		
		#Check if surpassing max ammount in fleet
		var ammInFleet = available_Recruits.count(RandomRec.Cpt)
		if (ammInFleet >= RandomRec.MaxAmmInFleet):
			recs.remove_at(randomIndex)
			continue
		
		#If cost allows add it to available recruits
		if (points > RandomRec.Cost):
			available_Recruits.append(RandomRec.Cpt.duplicate())
			points -= RandomRec.Cost

	return available_Recruits

#------------------------------------------------------------------------
#Returns a dictonary containing the filepath to the item as key and the ammount in the value
func GetWorkshopMerchForPosition(YPos: float, HasUp : bool, capital : bool) -> Dictionary[String, int]:
	var available_merch: Dictionary[String, int] = {}
	if (!HasUp):
		return available_merch
		
	var points = GetWorkshopMerchPointsForPosition(abs(YPos))
	if (capital):
		points *= 1.5

	var stage = Happening.GetStageForYPos(YPos)

	# Iterate through the MerchList to select merchandise based on points
	while points > MerchLowest:
		var randomIndex = Rand.InstanceRandom.RandIRange(0, WorkshopFileList.size() - 1)
		var m = ResourceLoader.load(WorkshopFileList[randomIndex]) as MerchandiseInfo
		
		if (m.DontGenerateBefore > stage):
			continue
		
		var it : String
		
		for itFile : String in available_merch:
			if (m.It == itFile):
				it = itFile
				break
		
		if (points > m.Cost):
			if (!it.is_empty()):
				available_merch[it] += 1

			else:
				available_merch[it] = 1
				
			points -= m.Cost
	return available_merch

#------------------------------------------------------------------------
func GetSpawnsForLocation(YPos : float, Patrol : bool, Convoy : bool, capital : bool) -> Array[Captain]:
	#var time = Time.get_ticks_msec()
	var stage = Happening.GetStageForYPos(YPos)
	var Fleet : Array[Captain] = []
	var Points = GetPointsForPosition(abs(YPos))
	if (capital):
		Points *= 1.5

	var CptnInfo = generate_fleet(Points, Patrol, Convoy, stage)
	for g in CptnInfo:
		var cpt = Captain.new()
		cpt.call_deferred("CopyStats", g.Cpt)
		Fleet.append(cpt)

	return Fleet

#------------------------------------------------------------------------
func GetPointsForPosition(YPos : float) -> int:
	return roundi(max(100, YPos / 50.0))

#------------------------------------------------------------------------
func GetMerchPointsForPosition(YPos : float) -> int:
	return roundi(max(20, YPos / 500.0))

#------------------------------------------------------------------------
func GetWorkshopMerchPointsForPosition(YPos : float) -> int:
	return roundi(max(20, YPos / 250.0))

#------------------------------------------------------------------------
func GetRecruitPointsForPosition(YPos : float) -> int:
	return roundi(max(50, YPos / 100.0))

#------------------------------------------------------------------------
func generate_fleet(points: int, Patrol : bool, Convoy : bool, stage : Happening.GameStage) -> Array[CaptainSpawnInfo]:
	var fleet : Array[CaptainSpawnInfo] = []
	var fleetFuelStats : Array[Dictionary]
	var MinimumRange = 0
	
	if (Patrol):
		MinimumRange = 8000
		
	var available_ships: Array = sorted_captain_list.duplicate()
	if (Patrol):
		points *= 3
	else : if (Convoy):
		points = 50
		available_ships = sorted_convoy_captain_list.duplicate()
	else:
		available_ships.append_array(sorted_ground_captain_list.duplicate())
	# Randomly shuffle the available ships to introduce variability in selection.
	#available_ships.shuffle()
	
	# While there's space in the fleet, try to maximize the points usage
	# with a dynamic strategy.
	while fleet.size() < 7 and points >= LowestPrice and available_ships.size() > 0:
		Rand.InstanceRandom.shuffle_array(available_ships)
		
		var selected_ship: CaptainSpawnInfo = null
		#var best_value = 0

		# Consider each ship for inclusion
		for shipIndex in range(available_ships.size() -1 , -1, -1):
			var ship : CaptainSpawnInfo = available_ships[shipIndex]
			if (ship.DontGenerateBefore > stage):
				available_ships.erase(ship)
				continue
			#if (fleet.size() == 0 and !ship.SpawnAlone):
				#continue
			
			var ShipRange = ship.Cpt.GetFuelStats()
			
			var FleetRange = GetFleetRange(fleetFuelStats, ShipRange)
			
			if (FleetRange < MinimumRange):
				available_ships.erase(ship)
				continue
			
			#if we will only have enough for one ship, dont take it.
			if (!Convoy and fleet.size() == 0 and points - ship.Cost < LowestPrice):
				available_ships.erase(ship)
				continue
			
			if points < ship.Cost:
				available_ships.erase(ship)
				continue
			# Calculate how many we can afford and consider its strategic value
			var max_ships = min(points / ship.Cost, ship.MaxAmmInFleet - fleet.count(ship))
			if max_ships > 0:
				selected_ship = ship
				break

		if selected_ship:
			fleet.append(selected_ship)
			fleetFuelStats.append(selected_ship.Cpt.GetFuelStats())
			points -= selected_ship.Cost
			if (selected_ship.MaxAmmInFleet == fleet.count(selected_ship)):
				available_ships.erase(selected_ship)
				
	return fleet

#------------------------------------------------------------------------
func GetFleetRange(OriginalFleetFuelStats : Array[Dictionary], NewShip : Dictionary) -> float:
	var fuel = NewShip["FUEL"]
	var fuel_ef = NewShip["F_EFF"]
	var fleetsize = 1 + OriginalFleetFuelStats.size()
	var total_fuel = fuel
	var inverse_ef_sum = 1.0 / fuel_ef
	
	# Group ships fuel and efficiency calculations
	for g in OriginalFleetFuelStats:
		var ship_fuel = g["FUEL"]
		var ship_efficiency = g["F_EFF"]
		total_fuel += ship_fuel
		inverse_ef_sum += 1.0 / ship_efficiency

	var effective_efficiency = fleetsize / inverse_ef_sum
	# Calculate average efficiency for the group
	return (total_fuel * effective_efficiency) / fleetsize

#------------------------------------------------------------------------
# Custom sort function: Sort by cost descending
static func SortByCostDescending(a :CaptainSpawnInfo, b : CaptainSpawnInfo):
	return b.Cost - a.Cost

extends Resource
class_name MapSpotType

@export var SpotK : SpotKind
#@export var MapIcon : Texture
#@export var Scene : PackedScene
#@export var PossibleDrops : Array[Item]
#@export var FullName : String
@export var Description : String
@export var VisibleOnStart : bool = false
@export var DropAmmount : int = 1


@export var CustomData : Array[MapSpotCustomData]
@export var PossibleHappenings : Array[Happening]

func GetCustomData(datname : String) -> Array[MapSpotCustomData]:
	var returnval : Array[MapSpotCustomData] = []
	for g in CustomData.size():
		if (CustomData[g].DataName == datname):
			returnval.append(CustomData[g])
	return returnval
func ClearCustomData(Dat : MapSpotCustomData):
	for g in CustomData.size():
		if (CustomData[g] == Dat):
			CustomData.remove_at(g)
			return
func GetEnumString() -> String:
	return SpotKind.keys()[SpotK]

func GetSpecialEvents() -> Array[Happening]:
	var SpEvents : Array[Happening] = []
	for g in PossibleHappenings:
		if (g.Special):
			SpEvents.append(g)
	return SpEvents
func GetNormalEvents() -> Array[Happening]:
	var Events : Array[Happening] = []
	for g in PossibleHappenings:
		if (!g.Special):
			Events.append(g)
	return Events
#func GetSpotDrop() -> Array[Item]:
	#var Drops : Array[Item] = []
	#for z in DropAmmount:
		#var it = PossibleDrops.pick_random()
		#var DropAmm = randi_range(1, it.RandomFindMaxCount)
		#for g in DropAmm :
			#Drops.append(it)
	#return Drops

func GetSpotEnumString(S : SpotKind) -> String:
	return SpotKind.keys()[S]

enum SpotKind{
CITY_CENTER,
VILLAGE,
CAPITAL,
}

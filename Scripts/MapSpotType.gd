extends Resource
class_name MapSpotType

@export var SpotK : SpotKind
@export var MapIcon : Texture
#@export var Scene : PackedScene
@export var PossibleDrops : Array[Item]
@export var FullName : String
@export var Description : String
@export var VisibleOnStart : bool = false
@export var DropAmmount : int = 1


@export var CustomData : Array[MapSpotCustomData]

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
	
func GetSpotDrop() -> Array[Item]:
	var Drops : Array[Item] = []
	for z in DropAmmount:
		var it = PossibleDrops.pick_random()
		var DropAmm = randi_range(1, it.RandomFindMaxCount)
		for g in DropAmm :
			Drops.append(it)
	return Drops

func GetSpotEnumString(S : SpotKind) -> String:
	return SpotKind.keys()[S]

enum SpotKind{
SHIP,
TERRESTRIAL_PLANET,
GAS,
LAVA,
ICE,
NO_ATMO,
SAND,
STAR,
STATION,
RINGED,
ASTEROID_BELT,
SUB_STATION,
CITY_CENTER,
VILLAGE,
POWER_PLANT,
AIRPORT,
OBSERVATORY,
OIL_RIG,
MILITARRY_BASE,
HOSPITAL
}

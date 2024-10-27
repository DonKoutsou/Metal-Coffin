extends Resource
class_name MapSpotType

@export var SpotK : SpotKind
@export var MapIcon : Texture
@export var Scene : PackedScene
@export var PossibleDrops : Array[Item]
@export var FullName : String
@export var Description : String
@export var CanLand : bool = false

func GetSpotDrop() -> Array[Item]:
	var Drops : Array[Item] = []
	var it = PossibleDrops.pick_random()
	var rng = RandomNumberGenerator.new()
	var DropAmm = rng.randi_range(1, it.RandomFindMaxCount)
	for g in DropAmm :
		Drops.append(it)
	return Drops

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
RINGED
}

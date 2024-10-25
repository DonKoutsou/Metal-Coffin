extends Resource
class_name MapSpotType

@export var SpotK : SpotKind
@export var MapIcon : Texture
@export var Scene : PackedScene
@export var PossibleDrops : Array[Item]
@export var FullName : String
@export var Description : String

enum SpotKind{
SHIP,
TERRESTRIAL_PLANET,
GAS,
LAVA,
ICE,
NO_ATMO,
SAND,
STAR,
STATION
}

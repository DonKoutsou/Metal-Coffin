extends Resource
class_name MapSpotCompleteInfo
@export var SpotName : String
@export var Region : REGIONS
#@export var Event : Happening
@export var EnemyCity : bool = false
@export var PossibleDrops : Array[Item]

var PickedBy : MapSpot



enum REGIONS{
	MAMDU,
	BAKYS,
	KIRS,
	ZAV,
}

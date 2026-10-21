extends Resource
class_name MapSpotCompleteInfo
@export var SpotName : String
@export var Region : REGIONS
#@export var Event : Happening
@export var EnemyCity : bool = false
@export var PossibleServices : Array[SERVICES]

var PickedBy : MapSpot

static var SERVICE_ICONS : Dictionary[SERVICES, String] = {
	SERVICES.FUEL : "res://Assets/Items/Fuel.png",
	SERVICES.REPAIR : "res://Assets/Items/Wrench.png",
	SERVICES.RECRUIT : "res://Assets/Items/upgrade.png",
	SERVICES.SHOP : "res://Assets/Items/cubeforcesmol.png",
} 

enum SERVICES{
	FUEL,
	REPAIR,
	RECRUIT,
	SHOP,
}

enum REGIONS{
	MAMDU,
	BAKYS,
	KIRS,
	ZAV,
}

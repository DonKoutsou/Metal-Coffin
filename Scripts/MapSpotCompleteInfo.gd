extends Resource
class_name MapSpotCompleteInfo
@export var SpotName : String
@export var Event : Happening
@export var EnemyCity : bool = false

@export var HostilePatrol : Array[Captain]
@export var HostilePatrolShipNames : Array[String]
@export var PossibleDrops : Array[Item]
@export var HostileGarrisson : Array[Captain]
@export var HostileGarrissonShipNames : Array[String]
var PickedBy : MapSpot

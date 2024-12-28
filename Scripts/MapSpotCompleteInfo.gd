extends Resource
class_name MapSpotCompleteInfo
@export var SpotName : String
@export var Event : Happening
@export var EnemyCity : bool = false

@export var HostilePatrolShipScene : PackedScene
@export var HostilePatrolShipName : String
@export var PossibleDrops : Array[Item]
@export var HostileShipScene : PackedScene
@export var HostileShipName : String
var PickedBy : MapSpot

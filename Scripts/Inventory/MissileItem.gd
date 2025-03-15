@tool
extends Item
class_name MissileItem

@export var MissileScene : PackedScene
#@export var MissileName : String
@export var Distance : int = 1500
@export var Speed : float = 1
@export var Damage : int = 30
@export var Type : MissileType

func GetItemDesc() -> String:
	var Desc 
	if (Type == 0):
		Desc = "{0}\n[color=#c19200]Range[/color] : {1} km\n[color=#c19200]Speed[/color] : {2} km/h\n[color=#c19200]Damage[/color] : {3}\n[color=#c19200]Type[/color] : {4}".format([ItemDesc, Distance, Map.SpeedToKmH(Speed), Damage, MissileType.find_key(Type)])
	else :
		Desc = "{0} \n[color=#c19200]Damage[/color] : {1} * Firepower\n[color=#c19200]Type[/color] : {2}".format([ItemDesc, Damage, MissileType.find_key(Type)])
	return Desc
enum MissileType
{
BVR,
WVR
}

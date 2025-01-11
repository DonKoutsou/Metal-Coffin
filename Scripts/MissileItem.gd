extends Item
class_name MissileItem

@export var MissileScene : PackedScene
@export var MissileName : String
@export var Distance : int = 1500
@export var Speed : float = 1
@export var Damage : int = 30

func GetItemDesc() -> String:
	return "{0} \n[color=#c19200]Range[/color] : {1} | [color=#c19200]Speed[/color] : {2}  | [color=#c19200]Damage[/color] : {3}".format([ItemDesc, Distance, Speed, Damage])

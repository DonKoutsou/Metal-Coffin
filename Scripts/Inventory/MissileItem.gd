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
	var Desc = "[color=#ffc315]REQUIRES MISSILE POD[/color]\n"
	if (Type == 0):
		Desc += "{0}\n[color=#ffc315]Range[/color] : {1} km\n[color=#ffc315]Speed[/color] : {2} km/h\n[color=#ffc315]Damage[/color] : {3}\n[color=#ffc315]Type[/color] : {4}".format([ItemDesc, Distance, roundi(Speed), Damage, MissileType.find_key(Type)])
	else :
		Desc += "{0} \n[color=#ffc315]Type[/color] : {1}".format([ItemDesc, MissileType.find_key(Type)])
	return Desc
	
func GetMerchItemDesc(Ships : Array[MapShip]) -> String:
	var Desc = "[color=#ffc315]REQUIRES MISSILE POD[/color]\n"
	var UsableOn : Array[MapShip]
	for g in Ships:
		if (g.Cpt.GetCharacterInventory().HasWeapon(CardStats.WeaponType.ML)):
			UsableOn.append(g)
	
	Desc += "CAN BE USED BY : [color=#ffc315]"
	if (UsableOn.size() > 0):
		for g in UsableOn:
			Desc += g.Cpt.GetCaptainName() + ", "
			
	Desc += "[/color]\n"
		
	if (Type == 0):
		Desc += "\n{0}\n[color=#ffc315]Range[/color] : {1} km\n[color=#ffc315]Speed[/color] : {2} km/h\n[color=#ffc315]Damage[/color] : {3}\n[color=#ffc315]Type[/color] : {4}".format([ItemDesc, Distance, roundi(Speed), Damage, MissileType.find_key(Type)])
	else :
		Desc += "\n{0} \n[color=#ffc315]Type[/color] : {1}".format([ItemDesc, MissileType.find_key(Type)])

	return Desc
enum MissileType
{
BVR,
WVR
}

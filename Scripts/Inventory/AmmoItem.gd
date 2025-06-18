@tool
extends Item

class_name AmmoItem

@export var WType : CardStats.WeaponType

func GetItemDesc() -> String:
	var Desc = "[color=#ffc315]REQUIRES {0}[/color]\n{1}".format([CardStats.WeaponType.keys()[WType],ItemDesc])
	return Desc

func GetMerchItemDesc(Ships : Array[MapShip]) -> String:
	var UsableOn : Array[MapShip]
	for g in Ships:
		if (g.Cpt.GetCharacterInventory().HasWeapon(WType)):
			UsableOn.append(g)
	
	var UsableOnText = "CAN BE USED BY : [color=#ffc315]"
	
	if (UsableOn.size() > 0):
		for g in UsableOn:
			UsableOnText += g.Cpt.GetCaptainName() + ", "
			
	UsableOnText += "[/color]\n"
		
	var Desc = "[color=#ffc315]REQUIRES {0}[/color]\n{2}\n{1}".format([CardStats.WeaponType.keys()[WType] ,ItemDesc, UsableOnText])
	return Desc

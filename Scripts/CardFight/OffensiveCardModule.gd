extends CardModule

class_name OffensiveCardModule

@export var AtackType : AtackTypes
@export var Damage : float
@export var CauseFile : bool
@export var OnSuccesfullAtackModules : Array[CardModule]

func GetDesc() -> String:
	var Desc = ""
	if (AOE):
		Desc = "Damage enemy team"
	else:
		Desc = "Damage enemy"
	Desc += " for [color=#c19200]{0} * FPWR[/color]".format([var_to_str(snapped(Damage, 0.1)).replace(".0", "")])
	if (OnSuccesfullAtackModules.size() > 0):
		Desc += "\n[color=#c19200]On Hit : [/color]"
		for g in OnSuccesfullAtackModules:
			Desc += g.GetDesc()
	if (CauseFile):
		Desc += "\n[color=#ff3c22]Causes fire[/color]"

	Desc += "\n[color=#c19200]{0}[/color]".format([ AtackTypes.keys()[AtackType].replace("_", " ")])
	
	return Desc

enum AtackTypes{
	DIRECT_ATACK,
	HOMING_ATACK,
	UNAVOIDABLE
}

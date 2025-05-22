extends CardModule

class_name OffensiveCardModule

@export var AtackType : AtackTypes
@export var Damage : float
@export var ScaleStat : CardModule.Stat
@export var CauseFile : bool
@export var OnSuccesfullAtackModules : Array[CardModule]

func GetFinalDamage(Performer : BattleShipStats) -> float:
	var Dmg : float
	if (ScaleStat == CardModule.Stat.FIREPOWER):
		Dmg = Damage * Performer.GetFirePower()
	else: if (ScaleStat == CardModule.Stat.SPEED):
		Dmg = Damage * Performer.GetSpeed()
	return Dmg

func GetDesc() -> String:
	var TextColor : String
	if (ScaleStat == Stat.FIREPOWER):
		TextColor = "color=#f35033"
	else : if (ScaleStat == Stat.SPEED):
		TextColor = "color=#308a4d"
		
	var Desc = ""
	if (AOE):
		Desc = "Damage enemy team"
	else:
		Desc = "Damage enemy"
	Desc += " for [color=#c19200]{0} * [/color][{2}]{1}[/color]".format([var_to_str(snapped(Damage, 0.1)).replace(".0", ""), CardModule.Stat.keys()[ScaleStat],TextColor])
	if (OnSuccesfullAtackModules.size() > 0):
		Desc += "\n[color=#c19200]On Hit : [/color]"
		for g in OnSuccesfullAtackModules:
			Desc += g.GetDesc()
	if (CauseFile):
		Desc += "\n[color=#ff3c22]Causes fire[/color]"

	Desc += "\n[color=#c19200]{0}[/color]".format([ AtackTypes.keys()[AtackType].replace("_", " ")])
	
	return Desc

func GetBattleDesc(User : BattleShipStats) -> String:
	var TextColor : String
	if (ScaleStat == Stat.FIREPOWER):
		TextColor = "color=#f35033"
	else : if (ScaleStat == Stat.SPEED):
		TextColor = "color=#308a4d"
		
	var Desc = ""
	if (AOE):
		Desc = "Damage enemy team"
	else:
		Desc = "Damage enemy"
	
	var FinalDamage : float
	if (ScaleStat == CardModule.Stat.FIREPOWER):
		FinalDamage = Damage * User.GetFirePower()
		
	else : if (ScaleStat == CardModule.Stat.SPEED):
		FinalDamage = Damage * User.GetSpeed()
		
	Desc += " for [{1}]{0}[/color] damage".format([snapped(FinalDamage, 0.1),TextColor]).replace(".0", "")
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

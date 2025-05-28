extends CardModule

class_name OffensiveCardModule

@export var AtackType : AtackTypes
@export var Damage : float
@export var ScaleStat : CardModule.Stat
@export var CauseFile : bool
@export var OnSuccesfullAtackModules : Array[CardModule]
@export var SkipShield : bool

func GetFinalDamage(Performer : BattleShipStats) -> float:
	var Dmg : float
	if (ScaleStat == CardModule.Stat.FIREPOWER):
		Dmg = Damage * Performer.GetFirePower()
	else: if (ScaleStat == CardModule.Stat.SPEED):
		Dmg = Damage * Performer.GetSpeed()
	else: if (ScaleStat == CardModule.Stat.WEIGHT):
		Dmg = Damage * Performer.GetWeight()
	else: if (ScaleStat == CardModule.Stat.DEFENCE):
		Dmg = Damage * Performer.GetDef()
	return Dmg

func GetDesc() -> String:
	var TextColor : String
	if (ScaleStat == Stat.FIREPOWER):
		TextColor = "color=#f35033"
	else : if (ScaleStat == Stat.SPEED):
		TextColor = "color=#308a4d"
	else : if (ScaleStat == Stat.DEFENCE):
		TextColor = "color=#7bb0b4"
	else : if (ScaleStat == Stat.WEIGHT):
		TextColor = "color=#828dff"
		
	var Desc = ""
	if (AOE):
		Desc = "Damage enemy team"
	else:
		Desc = "Damage enemy"
	Desc += " for [color=#ffc315]{0} * [/color][{2}]{1}[/color]".format([var_to_str(snapped(Damage, 0.1)).replace(".0", ""), CardModule.Stat.keys()[ScaleStat],TextColor])
	if (OnSuccesfullAtackModules.size() > 0):
		Desc += "\n[color=#ffc315]On Hit : [/color]"
		for g in OnSuccesfullAtackModules:
			Desc += g.GetDesc()
	if (CauseFile):
		Desc += "\n[color=#ff3c22]Causes fire[/color]"
	if (SkipShield):
		Desc += " [color=#ffc315]Skip's Shields[/color]"
	Desc += "\n[color=#ffc315]{0}[/color]".format([ AtackTypes.keys()[AtackType].replace("_", " ")])
	
	return Desc

func GetBattleDesc(User : BattleShipStats) -> String:
	var TextColor : String
	if (ScaleStat == Stat.FIREPOWER):
		TextColor = "color=#f35033"
	else : if (ScaleStat == Stat.SPEED):
		TextColor = "color=#308a4d"
	else : if (ScaleStat == Stat.DEFENCE):
		TextColor = "color=#7bb0b4"
	else : if (ScaleStat == Stat.WEIGHT):
		TextColor = "color=#828dff"
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
	
	else : if (ScaleStat == CardModule.Stat.WEIGHT):
		FinalDamage = Damage * User.GetWeight()
		
	Desc += " for [{1}]{0}[/color] damage".format([snapped(FinalDamage, 0.1),TextColor]).replace(".0", "")
	if (OnSuccesfullAtackModules.size() > 0):
		Desc += "\n[color=#ffc315]On Hit : [/color]"
		for g in OnSuccesfullAtackModules:
			Desc += g.GetDesc()
	if (CauseFile):
		Desc += "\n[color=#ff3c22]Causes fire[/color]"

	Desc += "\n[color=#ffc315]{0}[/color]".format([ AtackTypes.keys()[AtackType].replace("_", " ")])
	
	return Desc

enum AtackTypes{
	DIRECT_ATACK,
	HOMING_ATACK,
	UNAVOIDABLE
}

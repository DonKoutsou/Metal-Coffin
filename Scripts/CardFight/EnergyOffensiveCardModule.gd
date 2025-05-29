extends OffensiveCardModule

class_name EnergyOffensiveCardModule

var StoredEnergy : int = 0

func GetFinalDamage(Performer : BattleShipStats) -> float:
	var Dmg : float
	
	if (StoredEnergy > 0):
		Dmg = Damage * StoredEnergy
	else:
		Dmg = Damage * Performer.Energy

	return Dmg

func GetDesc() -> String:
	var Desc = ""
	if (AOE):
		Desc = "Hit enemy team"
	else:
		Desc = "Hit enemy"
		
	Desc += " for {0} * [color=#ffc315]Remaining Energy[/color] damage".format([var_to_str(Damage)])
	
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
	var Desc = ""
	if (AOE):
		Desc = "Hit enemy team"
	else:
		Desc = "Hit enemy"
	
	var En : int
	if (StoredEnergy > 0):
		En = StoredEnergy
	else :
		En = User.Energy
		
	Desc += " for\n[{0}]|[/color]{1}[{0}]|[/color] damage".format(["color=#ffc315", Damage * En])
	
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

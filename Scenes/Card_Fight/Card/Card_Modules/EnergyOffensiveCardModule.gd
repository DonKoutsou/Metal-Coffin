extends OffensiveCardModule

class_name EnergyOffensiveCardModule

var StoredEnergy : int = 0

func GetFinalDamage(Performer : BattleShipStats, Tier : int) -> float:
	var Dmg : float
	
	if (StoredEnergy > 0):
		Dmg = GetTieredDamage(Tier) * StoredEnergy
	else:
		Dmg = GetTieredDamage(Tier) * Performer.Energy

	return Dmg

func GetTieredDamage(Tier : int) -> float:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return Damage + (TierUpgrade * Tier)
	return Damage * max((TierUpgrade * Tier), 1)
	
func GetDesc(Tier : int) -> String:
	var Desc = ""
	if (AOE):
		Desc = "Hit enemy team"
	else:
		Desc = "Hit enemy"
		
	Desc += " for {0} * [color=#ffc315]Current Energy[/color] damage".format([var_to_str((GetTieredDamage(Tier)))])
	
	if (OnSuccesfullAtackModules.size() > 0):
		Desc += "\n[color=#ffc315]On Hit : [/color]"
		for g in OnSuccesfullAtackModules:
			Desc += g.GetDesc(Tier)
	if (CauseFile):
		Desc += "\n[color=#ff3c22]Causes fire[/color]"
	if (SkipShield):
		Desc += "\n[color=#ffc315]Skips Shields[/color]"
	Desc += "\n[color=#ffc315]{0}[/color]".format([ AtackTypes.keys()[AtackType].replace("_", " ")])
	
	return Desc

func GetBattleDesc(User : BattleShipStats, Tier : int) -> String:
	var Desc = ""
	if (AOE):
		Desc = "Hit enemy team"
	else:
		Desc = "Hit enemy"
		
	Desc += " for\n[{0}]|[/color]{1}[{0}]|[/color] damage".format(["color=#ffc315", GetFinalDamage(User, Tier)])
	
	if (OnSuccesfullAtackModules.size() > 0):
		Desc += "\n[color=#ffc315]On Hit : [/color]"
		for g in OnSuccesfullAtackModules:
			Desc += g.GetDesc(Tier)
	if (CauseFile):
		Desc += "\n[color=#ff3c22]Causes fire[/color]"
	if (SkipShield):
		Desc += "\n[color=#ffc315]Skips Shields[/color]"
	Desc += "\n[color=#ffc315]{0}[/color]".format([ AtackTypes.keys()[AtackType].replace("_", " ")])
	
	return Desc

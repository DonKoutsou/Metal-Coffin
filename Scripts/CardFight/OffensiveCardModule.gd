extends CardModule

class_name OffensiveCardModule

@export var AtackType : AtackTypes
@export var Damage : float
@export var ScaleStat : Array[DamageInfo]
@export var CauseFile : bool
@export var OnSuccesfullAtackModules : Array[CardModule]
@export var SkipShield : bool

func GetFinalDamage(Performer : BattleShipStats) -> float:
	var Dmg : float
	for Stat in ScaleStat:
		var StatAmm : float
		if (Stat.ScalingStat == CardModule.Stat.FIREPOWER):
			StatAmm = Performer.GetFirePower()
		else: if (Stat.ScalingStat == CardModule.Stat.SPEED):
			StatAmm = Performer.GetSpeed()
		else: if (Stat.ScalingStat == CardModule.Stat.WEIGHT):
			StatAmm = Performer.GetWeight()
		else: if (Stat.ScalingStat == CardModule.Stat.DEFENCE):
			StatAmm = Performer.GetDef()
		
		if (Stat.Method == DamageInfo.CalcuationMethod.ADD):
			Dmg += Stat.GetDamage(Damage, StatAmm)
		else : if (Stat.Method == DamageInfo.CalcuationMethod.MULTIPLY):
			Dmg *= Stat.GetDamage(Damage, StatAmm)
	return Dmg

func GetDesc() -> String:
	var TextColors : Array[String]
	for stat in ScaleStat:
		if (stat.ScalingStat == Stat.FIREPOWER):
			TextColors.append("color=#f35033")
		else : if (stat.ScalingStat == Stat.SPEED):
			TextColors.append("color=#308a4d")
		else : if (stat.ScalingStat == Stat.DEFENCE):
			TextColors.append("color=#7bb0b4")
		else : if (stat.ScalingStat == Stat.WEIGHT):
			TextColors.append("color=#828dff")
		
	var Desc = ""
	if (AOE):
		Desc = "Hit enemy team"
	else:
		Desc = "Hit enemy"
	
	var DamageString : String = ""
	for stat in ScaleStat.size():
		var DmgInfo = ScaleStat[stat] as DamageInfo
		
		var StatText = CardModule.Stat.keys()[DmgInfo.ScalingStat]
		if (DmgInfo.SelfMethod == DamageInfo.SelfCalcuationMethod.MULTIPLY):
			StatText += "²"
			
		if (stat > 0):
			if (DmgInfo.Method == DamageInfo.CalcuationMethod.ADD):
				DamageString += "+"
			else : if (DmgInfo.Method == DamageInfo.CalcuationMethod.MULTIPLY):
				DamageString += "*"
				
		DamageString += "[color=#ffc315]{0} * [/color][{2}]{1}[/color]".format([var_to_str(snapped(Damage, 0.1)).replace(".0", ""), StatText,TextColors[stat]])
		
		
	Desc += " for {0} damage".format([DamageString])
	
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
	var TextColors : Array[String]
	for stat in ScaleStat:
		if (stat.ScalingStat == Stat.FIREPOWER):
			TextColors.append("color=#f35033")
		else : if (stat.ScalingStat == Stat.SPEED):
			TextColors.append("color=#308a4d")
		else : if (stat.ScalingStat == Stat.DEFENCE):
			TextColors.append("color=#7bb0b4")
		else : if (stat.ScalingStat == Stat.WEIGHT):
			TextColors.append("color=#828dff")

	var Desc = ""
	if (AOE):
		Desc = "Hit enemy team"
	else:
		Desc = "Hit enemy"
	
	var FinalDamage : float
	
	for stat in ScaleStat:
		var Dmg : float
		if (stat.ScalingStat == CardModule.Stat.FIREPOWER):
			Dmg = stat.GetDamage(Damage, User.GetFirePower())
			
		else : if (stat.ScalingStat == CardModule.Stat.SPEED):
			Dmg = stat.GetDamage(Damage, User.GetSpeed())
		
		else : if (stat.ScalingStat == CardModule.Stat.WEIGHT):
			Dmg = stat.GetDamage(Damage, User.GetWeight())
		
		if (stat.Method == DamageInfo.CalcuationMethod.ADD):
			FinalDamage += Dmg
		if (stat.Method == DamageInfo.CalcuationMethod.MULTIPLY):
			FinalDamage *= Dmg
		
	var DamageString : String = var_to_str(snapped(FinalDamage, 0.1)).replace(".0", "")
	for stat in ScaleStat.size():
		DamageString = "[{0}]|[/color]{1}[{0}]|[/color]".format([TextColors[stat], DamageString])

		#var DmgInfo = ScaleStat[stat] as DamageInfo
		#
		#var StatText = CardModule.Stat.keys()[DmgInfo.ScalingStat]
		#if (DmgInfo.SelfMethod == DamageInfo.SelfCalcuationMethod.MULTIPLY):
			#StatText += "²"
			#
		##DamageString += "[color=#ffc315]{0} * [/color][{2}]{1}[/color]".format([var_to_str(snapped(FinalDamages[stat], 0.1)).replace(".0", ""), StatText,TextColors[stat]])
		#if (stat > 0):
			#if (DmgInfo.Method == DamageInfo.CalcuationMethod.ADD):
				#DamageString += "+"
			#else : if (DmgInfo.Method == DamageInfo.CalcuationMethod.MULTIPLY):
				#DamageString += "*"
				
		#DamageString += DamageString
		
		

	Desc += " for \n{0} damage".format([DamageString])
	
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

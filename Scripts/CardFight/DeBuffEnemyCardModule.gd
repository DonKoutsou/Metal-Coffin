extends OffensiveCardModule
class_name DeBuffEnemyModule

@export var StatToDeBuff : Stat
@export var DeBuffDuration : int
@export var DeBuffAmmount : float

func GetDesc(Tier : int) -> String:
	var TextColor : String
	if (StatToDeBuff == Stat.FIREPOWER):
		TextColor = "color=#f35033"
	else : if (StatToDeBuff == Stat.SPEED):
		TextColor = "color=#308a4d"
	else : if (StatToDeBuff == Stat.DEFENCE):
		TextColor = "color=#7bb0b4"
	else : if (StatToDeBuff == Stat.WEIGHT):
		TextColor = "color=#828dff"
	if (AOE):
		return "Debuff team\n[{3}] {0}[/color] by [color=#f35033]{1}%[/color] for {2} turns".format([Stat.keys()[StatToDeBuff], roundi(GetDebuffAmmount(Tier) * 100), GetDebuffDuration(Tier), TextColor])
	return "Debuff\n[{3}] {0}[/color] by [color=#f35033]{1}%[/color] for {2} turns".format([Stat.keys()[StatToDeBuff], roundi(GetDebuffAmmount(Tier) * 100), GetDebuffDuration(Tier), TextColor])

func GetBattleDesc(User : BattleShipStats, Tier : int) -> String:
	var TextColor : String
	if (StatToDeBuff == Stat.FIREPOWER):
		TextColor = "color=#f35033"
	else : if (StatToDeBuff == Stat.SPEED):
		TextColor = "color=#308a4d"
	else : if (StatToDeBuff == Stat.DEFENCE):
		TextColor = "color=#7bb0b4"
	else : if (StatToDeBuff == Stat.WEIGHT):
		TextColor = "color=#828dff"
	if (AOE):
		return "Debuff team\n[{3}] {0}[/color] by [color=#f35033]{1}%[/color] for {2} turns".format([Stat.keys()[StatToDeBuff], roundi(GetDebuffAmmount(Tier) * 100), GetDebuffDuration(Tier), TextColor])
	return "Debuff\n[{3}] {0}[/color] by [color=#f35033]{1}%[/color] for {2} turns".format([Stat.keys()[StatToDeBuff], roundi(GetDebuffAmmount(Tier) * 100), GetDebuffDuration(Tier), TextColor])

func GetDebuffDuration(Tier : int) -> int:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return roundi(DeBuffDuration + (TierUpgrade * Tier))
	return roundi(DeBuffDuration * max((TierUpgrade * Tier), 1))
	
func GetDebuffAmmount(Tier : int) -> float:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return snapped(DeBuffAmmount + (TierUpgrade * Tier), 0.1)
	return snapped(DeBuffAmmount *  max((TierUpgrade * Tier), 1), 0.1)

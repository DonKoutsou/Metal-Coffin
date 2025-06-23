extends CardModule

class_name DamageReductionCardModule

@export var CounterType : OffensiveCardModule.AtackTypes
@export var ReductionPercent : int
@export var OnSuccesfullDeffenceModules : Array[CardModule]

func GetDesc(Tier : int) -> String:
	var Desc = ""
	if (ReductionPercent > 0):
		Desc += "Reduce the damage of \n[color=#ffc315]{0}[/color] by {1}%".format([OffensiveCardModule.AtackTypes.keys()[CounterType].replace("_", " "), roundi(GetReductionPercent(Tier) * 100)])
	if (OnSuccesfullDeffenceModules.size() > 0):
		Desc += "\n[color=#ffc315]On Damaged[/color] : "
		for g in OnSuccesfullDeffenceModules:
			Desc += g.GetDesc(Tier)
	return Desc

func GetBattleDesc(User : BattleShipStats, Tier : int) -> String:
	var Desc = ""
	if (ReductionPercent > 0):
		Desc += "Reduce the damage of \n[color=#ffc315]{0}[/color] by {1}%".format([OffensiveCardModule.AtackTypes.keys()[CounterType].replace("_", " "), roundi(GetReductionPercent(Tier) * 100)])
	if (OnSuccesfullDeffenceModules.size() > 0):
		Desc += "\n[color=#ffc315]On Damaged[/color] : "
		for g in OnSuccesfullDeffenceModules:
			Desc += g.GetBattleDesc(User, Tier)
	return Desc

func GetReductionPercent(Tier : int) -> float:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return (ReductionPercent as float + (TierUpgrade * Tier)) / 100
	return (ReductionPercent as float * max((TierUpgrade * Tier), 1)) / 100

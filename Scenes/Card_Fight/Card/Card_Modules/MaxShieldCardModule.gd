extends DeffenceCardModule

class_name MaxShieldCardModule

@export var ShieldPerEnergy : int = 10

func GetDesc(Tier : int) -> String:
	if (AOE):
		return "[color=#ffc315]Remaining Energy[/color] * [color=#ffc315]{0}[/color] [color=#6be2e9]Shield[/color] for team".format([ShieldPerEnergy * GetShieldPerEnergy(Tier)])
	return "[color=#ffc315]Remaining Energy[/color] * [color=#ffc315]{0}[/color] [color=#6be2e9]Shield[/color] for self".format([ShieldPerEnergy * GetShieldPerEnergy(Tier)])


func GetBattleDesc(User : BattleShipStats, Tier : int) -> String:
	if (AOE):
		return "[color=#ffc315]{0}[/color] [color=#6be2e9]Shield[/color] for team".format([User.Energy * GetShieldPerEnergy(Tier)])
	return "[color=#ffc315]{0}[/color] [color=#6be2e9]Shield[/color] for self".format([User.Energy * GetShieldPerEnergy(Tier)])

func GetShieldPerEnergy(Tier : int) -> int:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return roundi(ShieldPerEnergy + (TierUpgrade * Tier))
	return roundi(ShieldPerEnergy * max((TierUpgrade * Tier), 1))

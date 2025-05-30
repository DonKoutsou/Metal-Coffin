extends DeffenceCardModule

class_name MaxShieldCardModule

@export var ShieldPerEnergy : int = 10

func GetDesc(Tier : int) -> String:
	if (AOE):
		return "[color=#ffc315]Remaining Energy[/color] * [color=#ffc315]{0}[/color] [color=#6be2e9]Shield[/color] for team".format([ShieldPerEnergy * max((TierUpgrade * Tier), 1)])
	return "[color=#ffc315]Remaining Energy[/color] * [color=#ffc315]{0}[/color] [color=#6be2e9]Shield[/color] for self".format([ShieldPerEnergy * max((TierUpgrade * Tier), 1)])


func GetBattleDesc(User : BattleShipStats, Tier : int) -> String:
	if (AOE):
		return "[color=#ffc315]{0}[/color] [color=#6be2e9]Shield[/color] for team".format([User.Energy * roundi(ShieldPerEnergy * max((TierUpgrade * Tier), 1))])
	return "[color=#ffc315]{0}[/color] [color=#6be2e9]Shield[/color] for self".format([User.Energy * roundi(ShieldPerEnergy * max((TierUpgrade * Tier), 1))])

func GetShieldPerEnergy(Tier : int) -> int:
	return roundi(ShieldPerEnergy * max((TierUpgrade * Tier), 1))

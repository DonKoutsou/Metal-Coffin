extends DeffenceCardModule
class_name BuffModule

@export var StatToBuff : Stat
@export var BuffDuration : int
@export var BuffAmmount : float

const StatText = "[color=#ffc315]HULL[/color][p][color=#6be2e9]SHIELD[/color][p][color=#308a4d]SPEED[/color][p][color=#f35033]FPWR[/color]"

func GetDesc(Tier : int) -> String:
	var TextColor : String
	if (StatToBuff == Stat.FIREPOWER):
		TextColor = "color=#f35033"
	else : if (StatToBuff == Stat.SPEED):
		TextColor = "color=#308a4d"
	if (StatToBuff == Stat.WEIGHT):
		TextColor = "color=#828dff"
	else : if (StatToBuff == Stat.DEFENCE):
		TextColor = "color=#7bb0b4"
	if (AOE):
		return "Buff team\n[{3}] {0}[/color][color=#ffc315] * {1}[/color] for {2} turns".format([Stat.keys()[StatToBuff], BuffAmmount * max((TierUpgrade * Tier), 1), roundi(BuffDuration * max((TierUpgrade * Tier), 1)), TextColor])
	else : if (CanBeUsedOnOther):
		return "Buff a ship\n[{3}] {0}[/color][color=#ffc315] * {1}[/color] for {2} turns".format([Stat.keys()[StatToBuff], BuffAmmount * max((TierUpgrade * Tier), 1), roundi(BuffDuration * max((TierUpgrade * Tier), 1)), TextColor])
	return "Buff self\n[{3}] {0}[/color][color=#ffc315] * {1}[/color] for {2} turns".format([Stat.keys()[StatToBuff], BuffAmmount * max((TierUpgrade * Tier), 1), roundi(BuffDuration * max((TierUpgrade * Tier), 1)), TextColor])

extends DeffenceCardModule
class_name LoseBuffSelfModule

@export var StatToStrip : Stat

func GetDesc(Tier : int) -> String:
	var TextColor : String
	if (StatToStrip == Stat.FIREPOWER):
		TextColor = "color=#f35033"
	else : if (StatToStrip == Stat.SPEED):
		TextColor = "color=#308a4d"
	else : if (StatToStrip == Stat.DEFENCE):
		TextColor = "color=#7bb0b4"
	else : if (StatToStrip == Stat.WEIGHT):
		TextColor = "color=#828dff"
	if (AOE):
		return "Strip enemy team [{1}]{0}[/color] buffs".format([Stat.keys()[StatToStrip], TextColor])
	return "Strip [{1}]{0}[/color] buffs from self".format([Stat.keys()[StatToStrip], TextColor])

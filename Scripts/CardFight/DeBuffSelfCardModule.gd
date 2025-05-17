extends DeffenceCardModule
class_name DeBuffSelfModule

@export var StatToDeBuff : Stat
@export var DeBuffDuration : int
@export var DeBuffAmmount : float

func GetDesc() -> String:
	var TextColor : String
	if (StatToDeBuff == Stat.FIREPOWER):
		TextColor = "color=#f35033"
	else : if (StatToDeBuff == Stat.SPEED):
		TextColor = "color=#308a4d"
	if (AOE):
		return "Debuff enemy team\n[{3}] {0}[/color][color=#308a4d] * {1}[/color] for {2} turns".format([Stat.keys()[StatToDeBuff], DeBuffAmmount, DeBuffDuration, TextColor])
	return "Debuff self\n[{3}] {0}[/color][color=#308a4d] * {1}[/color] for {2} turns".format([Stat.keys()[StatToDeBuff], DeBuffAmmount, DeBuffDuration, TextColor])

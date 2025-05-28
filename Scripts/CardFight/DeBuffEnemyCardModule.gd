extends OffensiveCardModule
class_name DeBuffEnemyModule

@export var StatToDeBuff : Stat
@export var DeBuffDuration : int
@export var DeBuffAmmount : float

func GetDesc() -> String:
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
		return "Debuff enemy team\n[{3}] {0}[/color] - [color=#f35033]{1}[/color] for {2} turns".format([Stat.keys()[StatToDeBuff], DeBuffAmmount, DeBuffDuration, TextColor])
	return "Debuff enemy\n[{3}] {0}[/color] - [color=#f35033]{1}[/color] for {2} turns".format([Stat.keys()[StatToDeBuff], DeBuffAmmount, DeBuffDuration, TextColor])

func GetBattleDesc(User : BattleShipStats) -> String:
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
		return "Debuff enemy team\n[{3}] {0}[/color] - [color=#f35033]{1}[/color] for {2} turns".format([Stat.keys()[StatToDeBuff], DeBuffAmmount, DeBuffDuration, TextColor])
	return "Debuff enemy\n[{3}] {0}[/color] - [color=#f35033]{1}[/color] for {2} turns".format([Stat.keys()[StatToDeBuff], DeBuffAmmount, DeBuffDuration, TextColor])

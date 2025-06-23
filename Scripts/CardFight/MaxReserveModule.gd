extends DeffenceCardModule
class_name MaxReserveModule

func GetDesc(_Tier : int) -> String:
	if (AOE):
		return "Converts all remaining [color=#ffc315]Energy[/color] as [color=#ffc315]Reserve[/color] to team"
	return "Converts all remaining [color=#ffc315]Energy[/color] as [color=#ffc315]Reserve[/color] to self"

func GetBattleDesc(User : BattleShipStats, _Tier : int) -> String:
	if (AOE):
		return "Converts {0} [color=#ffc315]Energy[/color] as [color=#ffc315]Reserve[/color] to team".format([User.Energy])
	return "Converts {0} [color=#ffc315]Energy[/color] as [color=#ffc315]Reserve[/color] to self".format([User.Energy])

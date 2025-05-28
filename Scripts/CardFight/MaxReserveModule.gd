extends DeffenceCardModule
class_name MaxReserveModule

func GetDesc() -> String:
	if (AOE):
		return "Adds all remaining [color=#ffc315]Energy[/color] as [color=#ffc315]Reserve[/color] to team"
	return "Adds all remaining [color=#ffc315]Energy[/color] as [color=#ffc315]Reserve[/color] to self"

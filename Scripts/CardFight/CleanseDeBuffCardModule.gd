extends DeffenceCardModule
class_name CleanseDebuffModule

const StatText = "[color=#ffc315]HULL[/color][p][color=#6be2e9]SHIELD[/color][p][color=#308a4d]SPEED[/color][p][color=#f35033]FPWR[/color]"

func GetDesc(_Tier : int) -> String:
	if (AOE):
		return "Cleanse all team debuffs."
	else : if (CanBeUsedOnOther):
		return "Cleanse all of a ship's debuffs."
	return "Cleanse all debuffs on self."

extends DeffenceCardModule
class_name MaxReserveModule

func GetDesc() -> String:
	if (AOE):
		return "Adds all remaining Energy as Reserve to team"
	return "Adds all remaining Energy as Reserve to self"

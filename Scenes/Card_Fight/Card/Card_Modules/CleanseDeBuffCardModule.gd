extends DeffenceCardModule
class_name CleanseDebuffModule

const StatText = "[color=#ffc315]HULL[/color][p][color=#6be2e9]SHIELD[/color][p][color=#308a4d]SPEED[/color][p][color=#f35033]FPWR[/color]"

func GetDesc(_Tier : int) -> String:
	if (AOE):
		return "Cleanse all team debuffs."
	else : if (CanBeUsedOnOther):
		return "Cleanse all of a ship's debuffs."
	return "Cleanse all debuffs on self."

func NeedsTargetSelect() -> bool:
	return true

func HandleDebuffCleanse(Performer : BattleShipStats, Targets : Array[BattleShipStats] = []) -> DeffensiveAnimationData:
	var TargetViz : Array[Control]
	
	var Callables : Array[Callable]
	
	for g in Targets:
		if (g == null):
			continue
		TargetViz.append(g.ShipViz)

		Callables.append(g.CleanseDebuffs)
	
	var Data = DeffensiveAnimationData.new()
	Data.Mod = self
	Data.Targets = TargetViz
	Data.Callables = Callables
	return Data

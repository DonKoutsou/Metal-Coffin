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

func NeedsTargetSelect() -> bool:
	return true

func Handle(Performer : BattleShipStats, Action : CardStats, Targets : Array[BattleShipStats] = []) -> AnimationData:
	if (Action.Burned):
		return DeffensiveAnimationData.new()
	var resupplyamm = Performer.Energy
			
	var TargetViz : Array[Control]
	
	for g in Targets:
		if (g == null):
			continue
		TargetViz.append(g.ShipViz)
		g.SetReserves(g.EnergyReserves + resupplyamm)
	
	Performer.SetEnergy(0)
	
	var Data = DeffensiveAnimationData.new()
	Data.Mod = self
	Data.Targets = TargetViz
	return Data

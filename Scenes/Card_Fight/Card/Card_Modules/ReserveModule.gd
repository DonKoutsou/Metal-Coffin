extends DeffenceCardModule
class_name ReserveModule

@export var ReserveAmmount : int = 5

func GetDesc(Tier : int) -> String:
	if (AOE):
		return "Adds [color=#ffc315]{0}[/color] Energy Reserve to team".format([GetEnergy(Tier)])
	return "Adds [color=#ffc315]{0}[/color] Energy Reserve to self".format([GetEnergy(Tier)])

func GetEnergy(Tier : int) -> int:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return roundi(ReserveAmmount + (Tier * TierUpgrade))
	return roundi(ReserveAmmount * max((Tier * TierUpgrade), 1))

func NeedsTargetSelect() -> bool:
	return true

func Handle(_Performer : BattleShipStats, Action : CardStats, Targets : Array[BattleShipStats] = []) -> AnimationData:
	if (Action.Burned):
		return DeffensiveAnimationData.new()
	var resupplyamm = GetEnergy(Action.Tier)

	var TargetViz : Array[Control]
	
	for g in Targets:
		if (g == null):
			continue
		TargetViz.append(g.ShipViz)
		g.SetReserves(g.EnergyReserves + resupplyamm)
			
	var Data = DeffensiveAnimationData.new()
	Data.Mod = self
	Data.Targets = TargetViz
	return Data

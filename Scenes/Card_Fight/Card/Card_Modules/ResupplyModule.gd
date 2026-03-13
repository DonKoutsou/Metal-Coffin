extends DeffenceCardModule
class_name ResupplyModule

@export var ResupplyAmmount : int = 1

func GetDesc(Tier : int) -> String:
	return "Adds [color=#ffc315]{0}[/color] Energy".format([GetEnergyAmmount(Tier)])

func GetEnergyAmmount(Tier : int) -> int:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return roundi(ResupplyAmmount + (TierUpgrade * Tier))
	return ResupplyAmmount * max((TierUpgrade * Tier), 1)

func NeedsTargetSelect() -> bool:
	return true

func HandleResupply(_Performer : BattleShipStats, Action : CardStats, Targets : Array[BattleShipStats] = []) -> DeffensiveAnimationData:
	var resupplyamm = GetEnergyAmmount(Action.Tier)
	
	var TargetViz : Array[Control]
	
	for g in Targets:
		if (g == null):
			continue
		TargetViz.append(g.ShipViz)
		
		g.SetEnergy(g.Energy + resupplyamm)
	
	var Data = DeffensiveAnimationData.new()
	Data.Mod = self
	Data.Targets = TargetViz
	return Data

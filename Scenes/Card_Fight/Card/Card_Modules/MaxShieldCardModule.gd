extends DeffenceCardModule

class_name MaxShieldCardModule

@export var ShieldPerEnergy : int = 10

func NeedsTargetSelect() -> bool:
	return true

func GetDesc(Tier : int) -> String:
	if (AOE):
		return "[color=#ffc315]Remaining Energy[/color] * [color=#ffc315]{0}[/color] [color=#6be2e9]Shield[/color] for team".format([ShieldPerEnergy * GetShieldPerEnergy(Tier)])
	return "[color=#ffc315]Remaining Energy[/color] * [color=#ffc315]{0}[/color] [color=#6be2e9]Shield[/color] for self".format([ShieldPerEnergy * GetShieldPerEnergy(Tier)])


func GetBattleDesc(User : BattleShipStats, Tier : int) -> String:
	if (AOE):
		return "[color=#ffc315]{0}[/color] [color=#6be2e9]Shield[/color] for team".format([User.Energy * GetShieldPerEnergy(Tier)])
	return "[color=#ffc315]{0}[/color] [color=#6be2e9]Shield[/color] for self".format([User.Energy * GetShieldPerEnergy(Tier)])

func GetShieldPerEnergy(Tier : int) -> int:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return roundi(ShieldPerEnergy + (TierUpgrade * Tier))
	return roundi(ShieldPerEnergy * max((TierUpgrade * Tier), 1))

func Handle(Performer : BattleShipStats, Action : CardStats, Targets : Array[BattleShipStats] = []) -> AnimationData:
	if (Action.Burned):
		return DeffensiveAnimationData.new()
	var ShieldAmm = Performer.Energy * GetShieldPerEnergy(Action.Tier)

	var TargetViz : Array[Control]
	
	var Callables : Array[Callable]
	
	for g in Targets:
		if (g == null):
			continue
		TargetViz.append(g.ShipViz)
		Callables.append(g.ShieldShip.bind(ShieldAmm))

	Performer.SetEnergy(0)
	
	var Data = DeffensiveAnimationData.new()
	Data.Mod = self
	Data.Targets = TargetViz
	Data.Callables = Callables
	return Data

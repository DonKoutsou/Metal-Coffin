extends DeffenceCardModule
class_name DeBuffSelfModule

@export var StatToDeBuff : Stat
@export var DeBuffDuration : int
@export var DeBuffAmmount : float

func NeedsTargetSelect() -> bool:
	return true

func GetDesc(Tier : int) -> String:
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
		return "Debuff team's\n[{3}] {0}[/color] - [color=#308a4d]{1}[/color] for {2} turns".format([Stat.keys()[StatToDeBuff], GetDebuffAmmount(Tier), GetDebuffDuration(Tier), TextColor])
	return "Debuff \n[{3}] {0}[/color] - [color=#308a4d]{1}[/color] for {2} turns".format([Stat.keys()[StatToDeBuff], GetDebuffAmmount(Tier), GetDebuffDuration(Tier), TextColor])

func GetBattleDesc(_User : BattleShipStats, Tier : int) -> String:
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
		return "Debuff team's\n[{3}] {0}[/color] - [color=#308a4d]{1}[/color] for {2} turns".format([Stat.keys()[StatToDeBuff], GetDebuffAmmount(Tier), GetDebuffDuration(Tier), TextColor])
	return "Debuff \n[{3}] {0}[/color] - [color=#308a4d]{1}[/color] for {2} turns".format([Stat.keys()[StatToDeBuff], GetDebuffAmmount(Tier), GetDebuffDuration(Tier), TextColor])

func GetDebuffDuration(Tier : int) -> int:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return roundi(DeBuffDuration + (TierUpgrade * Tier))
	return roundi(DeBuffDuration * max((TierUpgrade * Tier), 1))
	
func GetDebuffAmmount(Tier : int) -> float:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return snapped(DeBuffAmmount + (TierUpgrade * Tier), 0.1)
	return snapped(DeBuffAmmount *  max(pow(TierUpgrade, Tier), 1), 0.01)

func Handle(_Performer : BattleShipStats, Action : CardStats, Targets : Array[BattleShipStats] = []) -> AnimationData:
	if (Action.Burned):
		return DeffensiveAnimationData.new()
	var TargetViz : Array[Control]
	
	var Callables : Array[Callable]
	
	var DebuffAmmount = GetDebuffAmmount(Action.Tier)
	var DebuffDurration = GetDebuffDuration(Action.Tier)
	
	for g in Targets:
		if (g == null):
			continue
		TargetViz.append(g.ShipViz)

		if (StatToDeBuff == CardModule.Stat.FIREPOWER):
			Callables.append(g.DeBuffSpeed.bind(DebuffAmmount, DebuffDurration))
		else : if (StatToDeBuff == CardModule.Stat.SPEED):
			Callables.append(g.DeBuffSpeed.bind(DebuffAmmount, DebuffDurration))
		else : if (StatToDeBuff == CardModule.Stat.DEFENCE):
			Callables.append(g.DeBuffDefence.bind(DebuffAmmount, DebuffDurration))
			
	var Data = DeffensiveAnimationData.new()
	Data.Mod = self
	Data.Targets = TargetViz
	Data.Callables = Callables
	return Data

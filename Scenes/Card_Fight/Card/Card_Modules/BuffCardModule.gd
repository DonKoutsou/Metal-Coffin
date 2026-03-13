extends DeffenceCardModule
class_name BuffModule

@export var StatToBuff : Stat
@export var BuffDuration : int
@export var BuffAmmount : float

const StatText = "[color=#ffc315]HULL[/color][p][color=#6be2e9]SHIELD[/color][p][color=#308a4d]SPEED[/color][p][color=#f35033]FPWR[/color]"

func NeedsTargetSelect() -> bool:
	return true

func GetDesc(Tier : int) -> String:
	var TextColor : String
	if (StatToBuff == Stat.FIREPOWER):
		TextColor = "color=#f35033"
	else : if (StatToBuff == Stat.SPEED):
		TextColor = "color=#308a4d"
	if (StatToBuff == Stat.WEIGHT):
		TextColor = "color=#828dff"
	else : if (StatToBuff == Stat.DEFENCE):
		TextColor = "color=#7bb0b4"
	if (AOE):
		return "Buff team\n[{3}] {0}[/color][color=#ffc315] * {1}[/color] for {2} turns".format([Stat.keys()[StatToBuff], GetBuffAmmount(Tier), GetBuffDuration(Tier), TextColor])
	else : if (CanBeUsedOnOther):
		return "Buff a ship\n[{3}] {0}[/color][color=#ffc315] * {1}[/color] for {2} turns".format([Stat.keys()[StatToBuff], GetBuffAmmount(Tier), GetBuffDuration(Tier), TextColor])
	return "Buff\n[{3}] {0}[/color][color=#ffc315] * {1}[/color] for {2} turns".format([Stat.keys()[StatToBuff], GetBuffAmmount(Tier), GetBuffDuration(Tier), TextColor])

func GetBuffDuration(Tier : int) -> int:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return roundi(BuffDuration + (TierUpgrade * Tier))
	return roundi(BuffDuration * max((TierUpgrade * Tier), 1))
	
func GetBuffAmmount(Tier : int) -> float:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return BuffAmmount +(TierUpgrade * Tier)
	return BuffAmmount * max((TierUpgrade * Tier), 1)

func HandleBuff(_Performer : BattleShipStats, Action : CardStats, Targets : Array[BattleShipStats] = []) -> DeffensiveAnimationData:
	var TargetViz : Array[Control]
	
	var Callables : Array[Callable]
	
	var DebuffAmmount = GetBuffAmmount(Action.Tier)
	var DebuffDurration = GetBuffDuration(Action.Tier)
	
	for g in Targets:
		if (g == null):
			continue
		TargetViz.append(g.ShipViz)
		
		if (StatToBuff == CardModule.Stat.FIREPOWER):
			Callables.append(g.BuffFirePower.bind(DebuffAmmount, DebuffDurration))
		else : if (StatToBuff == CardModule.Stat.SPEED):
			Callables.append(g.BuffSpeed.bind(DebuffAmmount, DebuffDurration))
		else : if (StatToBuff == CardModule.Stat.DEFENCE):
			Callables.append(g.BuffDefence.bind(DebuffAmmount, DebuffDurration))
		
	var Data = DeffensiveAnimationData.new()
	Data.Mod = self
	Data.Targets = TargetViz
	Data.Callables = Callables
	return Data

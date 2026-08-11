extends DeffenceCardModule
class_name BuffNextAttackModule

@export var BuffDuration : int
@export var BuffAmmount : float

const StatText = "[color=#ffc315]HULL[/color][p][color=#6be2e9]SHIELD[/color][p][color=#308a4d]SPEED[/color][p][color=#f35033]FPWR[/color]"

func NeedsTargetSelect() -> bool:
	return true

func GetDesc(Tier : int, _targetOverride : String = "") -> String:
	if (AOE):
		return "[[CT_BUFFTS]] [[CT_NEXT]] [color=#ffc315]{1} CT_ATTACKS[/color] [[CT_BY]] [color=#f35033]* {0}[/color]".format([GetBuffAmmount(Tier), GetBuffDuration(Tier)])
	else : if (CanBeUsedOnOther):
		return "[[CT_BUFFSs]] [[CT_NEXT]] [color=#ffc315]{1} CT_ATTACKS[/color] [[CT_BY]] [color=#f35033]* {0}[/color]".format([GetBuffAmmount(Tier), GetBuffDuration(Tier)])
	return "[[CT_BUFFSS]] [[CT_NEXT]] [color=#ffc315]{1} CT_ATTACKS[/color] [[CT_BY]] [color=#f35033]* {0}[/color]".format([GetBuffAmmount(Tier), GetBuffDuration(Tier)])

func GetBuffDuration(Tier : int) -> int:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return roundi(BuffDuration + (TierUpgrade * Tier))
	return roundi(BuffDuration * max((TierUpgrade * Tier), 1))
	
func GetBuffAmmount(Tier : int) -> float:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return BuffAmmount +(TierUpgrade * Tier)
	return BuffAmmount * max((TierUpgrade * Tier), 1)

func Handle(_Performer : BattleShipStats, Action : CardStats, Targets : Array[BattleShipStats] = []) -> AnimationData:
	if (Action.Burned):
		return DeffensiveAnimationData.new()
	var TargetViz : Array[Control]
	
	var Callables : Array[Callable]
	
	var DebuffAmmount = GetBuffAmmount(Action.Tier)
	var DebuffDurration = GetBuffDuration(Action.Tier)
	
	for g in Targets:
		if (g == null):
			continue
		TargetViz.append(g.ShipViz)

		Callables.append(g.BuffNextAttack.bind(DebuffAmmount, DebuffDurration))

	var Data = DeffensiveAnimationData.new()
	Data.Mod = self
	Data.Targets = TargetViz
	Data.Callables = Callables
	return Data

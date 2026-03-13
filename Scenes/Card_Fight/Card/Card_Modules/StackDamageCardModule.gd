extends CardModule
class_name StackDamageCardModule

@export var BuffAmmount : float

func GetDesc(Tier : int) -> String:
	return "Card damage {0}%".format([GetStackDamage(Tier)])

func GetStackDamage(Tier : int) -> float:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return roundi(BuffAmmount + (TierUpgrade * Tier) * 100)
	return roundi(BuffAmmount * max((TierUpgrade * Tier), 1) * 100)

func NeedsTargetSelect() -> bool:
	return false

func HandleDamageStack(_Performer : BattleShipStats, Action : CardStats) -> DeffensiveAnimationData:
	var OffensiveModule = Action.OnPerformModule.duplicate() as OffensiveCardModule
	var NewAction = Action.duplicate()
	NewAction.OnPerformModule = OffensiveModule
	Action = NewAction
	OffensiveModule.Damage += OffensiveModule.Damage * GetStackDamage(Action.Tier)
	var Targets : Array[Control]
	var Data = DeffensiveAnimationData.new()
	Data.Mod = self
	Data.Targets = Targets
	return Data

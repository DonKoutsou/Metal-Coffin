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

func Handle(_Performer : BattleShipStats, Action : CardStats, Targets : Array[BattleShipStats] = []) -> AnimationData:
	if (Action.Burned):
		return DeffensiveAnimationData.new()
	var OffensiveModule = Action.OnPerformModule.duplicate() as OffensiveCardModule
	var NewAction = Action.duplicate()
	NewAction.OnPerformModule = OffensiveModule
	Action = NewAction
	OffensiveModule.Damage += OffensiveModule.Damage * GetStackDamage(Action.Tier)
	var Data = DeffensiveAnimationData.new()
	Data.Mod = self
	#Data.Targets = Targets
	return Data

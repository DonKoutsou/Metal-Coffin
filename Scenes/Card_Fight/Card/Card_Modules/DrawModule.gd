extends CardModule
class_name DrawCardModule

@export var DrawAmmount : int
@export var DiscardAmmount : int

func GetDesc(Tier : int) -> String:
	if (DiscardAmmount > 0):
		return "Draw {0}, Discard {1}".format([GetDrawAmmount(Tier), DiscardAmmount])
	return "Draw {0}".format([GetDrawAmmount(Tier)])

func GetDrawAmmount(Tier : int) -> int:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return roundi(DrawAmmount + roundi((TierUpgrade * Tier)))
	return roundi(DrawAmmount * roundi(max((TierUpgrade * Tier), 1)))

func NeedsTargetSelect() -> bool:
	return false

func Handle(Performer : BattleShipStats, Action : CardStats, Targets : Array[BattleShipStats] = []) -> AnimationData:
	if (Action.Burned):
		return DeffensiveAnimationData.new()
	var drawAmm = GetDrawAmmount(Action.Tier)
	Performer.deck.DrawMulti(drawAmm, DiscardAmmount)
	return null

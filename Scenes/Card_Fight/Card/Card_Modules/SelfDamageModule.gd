extends CardModule
class_name SelfDamageModule

@export var Damage : float

func GetDesc(Tier : int) -> String:
	return "Cause [color=#ffc315]{0}[/color] damage to self".format([GetFinalDamage(Tier)]).replace(".0", "")

func GetFinalDamage(Tier : int) -> float:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return Damage + (TierUpgrade * Tier)
	return Damage * max((TierUpgrade * Tier), 1)

func NeedsTargetSelect() -> bool:
	return false

func Handle(Performer : BattleShipStats, Action : CardStats, Targets : Array[BattleShipStats] = []) -> AnimationData:
	if (Action.Burned):
		return DeffensiveAnimationData.new()
	var Callables : Array[Callable]
	Callables.append(Performer.DamageShip.bind(GetFinalDamage(Action.Tier)))
	
	var AnimData = OffensiveAnimationData.new()
	AnimData.Mod = self
	
	var Data : Dictionary
	Data["Def"] = null
	Data["Viz"] = Performer.ShipViz
	var DefList : Dictionary[BattleShipStats, Dictionary]
	DefList[Performer] = Data
	AnimData.DeffenceList = DefList
	
	AnimData.Callables = Callables
	
	return AnimData

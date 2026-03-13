extends DeffenceCardModule
class_name ReserveConversionModule

@export var ConversionMultiplication : Curve

func GetDesc(_Tier : int) -> String:
	#if (AOE):
		#return "Coverst remaining Energy Reserve to double the Energy to team"
	return "Coverts remaining [color=#ffc315]Reserve[/color] to [color=#ffc315]Energy[/color]"


func GetBattleDesc(User : BattleShipStats, Tier : int) -> String:
	return "Coverts remaining [color=#ffc315]Reserve[/color] to [color=#ffc315]{0} Energy[/color]".format([GetConversionAmmount(User.EnergyReserves, Tier)])

func GetConversionAmmount(ReserveAmm : int, Tier : int) -> int:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return roundi(ReserveAmm * (ConversionMultiplication.sample(ReserveAmm) + (TierUpgrade * Tier)))
	return roundi(ReserveAmm * (ConversionMultiplication.sample(ReserveAmm) * max((TierUpgrade * Tier), 1)))

func NeedsTargetSelect() -> bool:
	return false

func HandleReserveConversion(Performer : BattleShipStats, Action : CardStats, Targets : Array[BattleShipStats] = []) -> DeffensiveAnimationData:
	var resupplyamm = GetConversionAmmount(Performer.EnergyReserves, Action.Tier)
	
	Performer.SetReserves(0)
	Performer.SetEnergy(Performer.Energy + resupplyamm)

	var TargetViz : Array[Control]
	TargetViz.append(Performer.ShipViz)
	var Data = DeffensiveAnimationData.new()
	Data.Mod = self
	Data.Targets = TargetViz
	return Data

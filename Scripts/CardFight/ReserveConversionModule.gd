extends DeffenceCardModule
class_name ReserveConversionModule

@export var ConversionMultiplication : Curve

func GetDesc() -> String:
	#if (AOE):
		#return "Coverst remaining Energy Reserve to double the Energy to team"
	return "Coverts remaining [color=#ffc315]Reserve[/color] to double the [color=#ffc315]Energy[/color]"


func GetBattleDesc(User : BattleShipStats) -> String:
	return "Coverts remaining [color=#ffc315]Reserve[/color] to [color=#ffc315]{0} Energy[/color]".format([GetConversionAmmount(User.EnergyReserves)])

func GetConversionAmmount(ReserveAmm : int) -> int:
	return roundi(ReserveAmm * ConversionMultiplication.sample(ReserveAmm))

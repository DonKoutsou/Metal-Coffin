extends CardStats
class_name OffensiveCardStats

@export var CounteredBy : CardStats
@export var Damage : float
@export var Accuracy : float
@export var CauseFile : bool

func GetDamage() -> float:
	#if (SelectedOption):
		#return (Damage + SelectedOption.DamageFlat) * Tier * SelectedOption.DamageMult
	return Damage

func CauseFire() -> bool:
	#if (SelectedOption):
		#return SelectedOption.Fire
	return CauseFile

func GetCounter() -> CardStats:
	#if (SelectedOption != null and SelectedOption.NegateCounter):
		#return null
	
	return CounteredBy

func GetDescription() -> String:
	#if is_instance_valid(SelectedOption):
		#return SelectedOption.OptionDescription + "[color=#c19200]DMG = {0} * FPWR[/color]".format([var_to_str(snapped(GetDamage(), 0.1)).replace(".0", "")])
	return CardDescription + "[color=#c19200]DMG = {0} * FPWR[/color]".format([var_to_str(snapped(GetDamage(), 0.1)).replace(".0", "")])

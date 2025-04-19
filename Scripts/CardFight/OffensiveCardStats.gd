extends CardStats
class_name OffensiveCardStats

@export var CounteredBy : CardStats
@export var Damage : float
@export var Accuracy : float

func GetDamage() -> float:
	if (SelectedOption):
		return (Damage + SelectedOption.DamageFlat) * Tier * SelectedOption.DamageMult
	return Damage

func CauseFire() -> bool:
	if (SelectedOption):
		return SelectedOption.Fire
	return false

func IsPorximityFuse() -> bool:
	if (SelectedOption):
		return SelectedOption.Proxy
	return false

func GetCounter() -> CardStats:
	if (SelectedOption != null and SelectedOption.NegateCounter):
		return null
	
	return CounteredBy

func GetDescription() -> String:
	if is_instance_valid(SelectedOption):
		return SelectedOption.OptionDescription + "[color=#c19200]DMG = {0} * FPWR[/color]".format([GetDamage()])
	return CardDescription + "[color=#c19200]DMG = {0} * FPWR[/color]".format([GetDamage()])

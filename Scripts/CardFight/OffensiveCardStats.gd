extends CardStats
class_name OffensiveCardStats

@export var CounteredBy : CardStats
@export var Damage : float

func GetDamage() -> float:
	if (SelectedOption):
		return (Damage + SelectedOption.DamageFlat) * SelectedOption.DamageMult
	return Damage

func CauseFire() -> bool:
	if (SelectedOption):
		return SelectedOption.Fire
	return false

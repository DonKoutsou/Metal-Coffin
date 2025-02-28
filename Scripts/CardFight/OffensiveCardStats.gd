extends CardStats
class_name OffensiveCardStats

@export var CounteredBy : CardStats
@export var Damage : float
@export var Accuracy : float

func GetDamage() -> float:
	if (SelectedOption):
		return (Damage + SelectedOption.DamageFlat) * SelectedOption.DamageMult
	return Damage

func CauseFire() -> bool:
	if (SelectedOption):
		return SelectedOption.Fire
	return false

func IsPorximityFuse() -> bool:
	if (SelectedOption):
		return SelectedOption.Proxy
	return false

extends DeffenceCardModule
class_name BuffModule

@export var StatToBuff : Stat
@export var BuffDuration : int
@export var BuffAmmount : float


func GetDesc() -> String:
	if (AOE):
		return "Buff team\n[color=#308a4d] {0} * {1}[/color] for {2} turns".format([Stat.keys()[StatToBuff], BuffAmmount, BuffDuration])
	return "Buff self\n[color=#308a4d] {0} * {1}[/color] for {2} turns".format([Stat.keys()[StatToBuff], BuffAmmount, BuffDuration])

enum Stat{
	FIREPOWER,
	SPEED
}

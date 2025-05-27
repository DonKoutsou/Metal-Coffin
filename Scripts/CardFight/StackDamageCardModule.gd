extends CardModule
class_name StackDamageCardModule

@export var BuffAmmount : float

func GetDesc() -> String:
	return "Card damage + {0}%".format([BuffAmmount * 100])

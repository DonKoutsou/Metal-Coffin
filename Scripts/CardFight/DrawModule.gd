extends CardModule
class_name DrawCardModule

@export var DrawAmmount : int
@export var DiscardAmmount : int

func GetDesc() -> String:
	return "Draw {0}, Discard {1}".format([DrawAmmount, DiscardAmmount])

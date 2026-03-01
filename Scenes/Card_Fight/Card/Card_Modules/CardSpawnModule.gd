extends CardModule
class_name CardSpawnModule

@export var CardToSpawn : CardStats

func GetDesc(_Tier : int) -> String:
	return "Draw a {0} from the deck".format([CardToSpawn.GetCardName()])

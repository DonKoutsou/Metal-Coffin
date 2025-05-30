extends CardModule
class_name OffensiveCardSpawnModule

@export var CardToSpawn : CardStats

func GetDesc(Tier : int) -> String:
	return "Draw a {0} from the deck".format([CardToSpawn.GetCardName()])

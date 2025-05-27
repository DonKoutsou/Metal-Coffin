extends CardModule
class_name MultiCardSpawnModule

@export var CardToSpawn : CardType

func TestCard(Mod : CardModule) -> bool:
	if (CardToSpawn == CardType.OFFENSIVE and Mod is OffensiveCardModule):
		return true
	if (CardToSpawn == CardType.DEFENSIVE and Mod is DeffenceCardModule):
		return true
	return false

func GetDesc() -> String:
	return "Choose one {0} card from the deck".format([CardType.keys()[CardToSpawn]])

enum CardType {
	OFFENSIVE,
	DEFENSIVE
}

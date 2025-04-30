extends Object

class_name CardFightActionList

var List : Dictionary

func GetList() -> Dictionary:
	return List

func GetShipsActions(Ship : BattleShipStats) -> Array:
	if (!List.keys().has(Ship)):
		return []
	return List[Ship]

func AddAction(Instigator : BattleShipStats, Action : CardFightAction) -> void:
	List[Instigator].append(Action)

func ShipHasAction(Ship : BattleShipStats, Action : CardStats) -> bool:
	for g in List[Ship]:
		var act = g as CardFightAction
		if (act.Action.CardName == Action.CardName):
			return true
	return false

func RemoveActionFromShip(Ship : BattleShipStats, Action : CardStats) -> void:
	for g in List[Ship]:
		var act = g as CardFightAction
		if (act.Action.CardName == Action.CardName):
			List[Ship].erase(act)
			return

func AddShip(Ship : BattleShipStats) -> void:
	List[Ship] = []

func RemoveShip(Ship : BattleShipStats) -> void:
	List.erase(Ship)

func Clear() -> void:
	List.clear()

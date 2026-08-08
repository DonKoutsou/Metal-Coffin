extends RefCounted

class_name CardfightPassiveList

var List : Dictionary

func GetList() -> Dictionary:
	return List

func GetShipsActions(Ship : BattleShipStats) -> Array:
	if (!List.keys().has(Ship)):
		return []
	return List[Ship]

func AddPassive(Instigator : BattleShipStats, Passive : Card_Passive) -> void:
	List[Instigator].append(Passive)

func RemovePassiveFromShip(Ship : BattleShipStats, Passive : Card_Passive) -> void:
	List[Ship].erase(Passive)

func AddShip(Ship : BattleShipStats) -> void:
	List[Ship] = []

func RemoveShip(Ship : BattleShipStats) -> void:
	List.erase(Ship)

func Clear() -> void:
	List.clear()

func OnActionPerformed(actionType : Card_Passive.ActionType, Performer : BattleShipStats) -> void:
	for ship : BattleShipStats in List:
		for passive : Card_Passive in List[ship]:
			passive.OnActionPerformed(actionType, Performer, ship)

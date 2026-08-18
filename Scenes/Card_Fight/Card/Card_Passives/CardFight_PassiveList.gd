extends RefCounted

class_name CardfightPassiveList

var List : Dictionary

func GetList() -> Dictionary:
	return List

func GetShipsActions(Ship : BattleShipStats) -> Array:
	if (!List.keys().has(Ship)):
		return []
	return List[Ship]

func AddPassive(Instigator : BattleShipStats, Passive : CardStats) -> void:
	List[Instigator].append(Passive)

func RemovePassiveFromShip(Ship : BattleShipStats, Passive : CardStats) -> void:
	List[Ship].erase(Passive)

func AddShip(Ship : BattleShipStats) -> void:
	List[Ship] = []

func RemoveShip(Ship : BattleShipStats) -> void:
	List.erase(Ship)

func ClearShipPassives(Ship : BattleShipStats) -> void:
	List[Ship].clear()

func Clear() -> void:
	List.clear()

func OnActionPerformed(data : Dictionary) -> Array[PassiveAnimationData]:
	var Type : Card_Passive.ActionType = data["actionType"]
	
	var Anim : Array[PassiveAnimationData] = []
	for ship : BattleShipStats in List:
		for card : CardStats in List[ship]:
			if (card.Passive.GetTrigger() != Type):
				continue
			
			var anim : PassiveAnimationData = card.Passive.OnActionPerformed(data, card, ship)
			if (anim != null):
				anim.OriginalCard = card
				Anim.append(anim)
	return Anim

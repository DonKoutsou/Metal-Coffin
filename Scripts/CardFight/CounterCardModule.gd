extends CardModule

class_name CounterCardModule

@export var CounterType : OffensiveCardModule.AtackTypes

@export var OnSuccesfullDeffenceModules : Array[CardModule]

func GetDesc(Tier : int) -> String:
	var Desc = "Avoid an incomming\n[color=#ffc315]{0}[/color]".format([OffensiveCardModule.AtackTypes.keys()[CounterType].replace("_", " ")])
	if (OnSuccesfullDeffenceModules.size() > 0):
		Desc += "\n[color=#ffc315]On Counter[/color] : "
		for g in OnSuccesfullDeffenceModules:
			Desc += g.GetDesc(Tier)
	return Desc

func GetBattleDesc(User : BattleShipStats, Tier : int) -> String:
	var Desc = "Avoid an incomming\n[color=#ffc315]{0}[/color]".format([OffensiveCardModule.AtackTypes.keys()[CounterType].replace("_", " ")])
	if (OnSuccesfullDeffenceModules.size() > 0):
		Desc += "\n[color=#ffc315]On Counter[/color] : "
		for g in OnSuccesfullDeffenceModules:
			Desc += g.GetBattleDesc(User, Tier)
	return Desc

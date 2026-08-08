
extends Card_Passive

class_name ShieldOnDraw_Passive

@export var ShieldAmm : int = 10

@export var SelfOnly : bool
@export var OnlyFriendly : bool

func OnActionPerformed(actionType : ActionType, Performer : BattleShipStats, PassiveOwner : BattleShipStats) -> void:
	if (actionType != ActionType.CARD_DRAW):
		return
	
	if (SelfOnly and Performer != PassiveOwner):
		return
	
	if (OnlyFriendly and Performer.Friendly != PassiveOwner.Friendly):
		return
	
	PassiveOwner.ShieldShip(ShieldAmm)
	PassiveOwner.ShipViz.DoFloater("Shield +", Color(1,1,1))

func GetDesc(_Tier : int) -> String:
	return "On Draw Get Shield"

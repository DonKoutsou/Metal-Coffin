@abstract 
extends Resource

class_name Card_Passive

@abstract
func OnActionPerformed(actionType : ActionType, Performer : BattleShipStats, PassiveOwner : BattleShipStats) -> void

@abstract
func GetDesc(_Tier : int) -> String

enum ActionType
{
	CARD_DRAW,
	DAMAGED,
	PLAYED_CARD,
}

@abstract 
extends Resource

class_name Card_Passive

@abstract
func OnActionPerformed(data : Dictionary, PassiveOwner : BattleShipStats) -> PassiveAnimationData

@abstract
func GetDesc(_Tier : int) -> String

enum ActionType
{
	CARD_DRAW,
	DAMAGED,
	PLAYED_CARD,
	CARD_DISCARD,
}

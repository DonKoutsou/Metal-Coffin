@abstract
extends Resource

class_name Card_Passive

@export var Module : CardModule
@export var Receiver : ReceiverType = ReceiverType.OWNER
@export var Target : TargetType = TargetType.OWNER

#------------------------------------------------------
@abstract
func OnActionPerformed(data : Dictionary, C : CardStats, PassiveOwner : BattleShipStats) -> PassiveAnimationData

#------------------------------------------------------
func GetDesc(Tier : int) -> String:
	return "{0}\n{1}".format([GetTrigerString() ,Module.GetDesc(Tier, GetTargetString())])

#------------------------------------------------------
func GetBattleDesc(User : BattleShipStats,Tier : int) -> String:
	return "{0}\n{1}".format([GetTrigerString() ,Module.GetBattleDesc(User, Tier, GetTargetString())])

#------------------------------------------------------
func GetTargetString() -> String:
	var targetString : String = TargetType.keys()[Target]
	targetString = targetString.replace("_", " ")
	return "[color=#ffc315]{0}[/color]".format([targetString])

#------------------------------------------------------
func GetTrigerString() -> String:
	var triggerString : String = ActionType.keys()[GetTrigger()].replace("_", " ")
	var receiverString : String = ReceiverType.keys()[Receiver].replace("_", " ")
	
	return "[color=#ffc315]ON {0} BY {1}[/color]".format([triggerString, receiverString])

#------------------------------------------------------
@abstract
func GetTrigger() -> ActionType

#------------------------------------------------------
func GetPossibleReceivers(data : Dictionary, PassiveOwner : BattleShipStats) -> Array[BattleShipStats]:
	var targets : Array[BattleShipStats] = []
	if (Receiver == ReceiverType.OWNER):
		targets.append(PassiveOwner)
		
	else: if (Receiver == ReceiverType.ANY_FRIENDLY):
		var friendly : Array[BattleShipStats] = data["Friendly"].duplicate()
		friendly.erase(PassiveOwner)
		targets.append_array(friendly)
		
	else: if (Receiver == ReceiverType.ANY_FRIENDLY_INCLUSIVE):
		targets.append_array(data["Friendly"])
		
	else: if (Receiver == ReceiverType.ANY_ENEMY):
		targets.append_array(data["Enemy"])
		
	else: if (Receiver == ReceiverType.ANY_SHIP):
		targets.append_array(data["Friendly"])
		targets.append_array(data["Enemy"])
		
	return targets

#------------------------------------------------------
func GetPossibleTargets(data : Dictionary, PassiveOwner : BattleShipStats) -> Array[BattleShipStats]:
	var targets : Array[BattleShipStats] = []
	if (Target == TargetType.OWNER):
		targets.append(PassiveOwner)
		
	else: if (Target == TargetType.RANDOM_FRIENDLY):
		var friendly : Array[BattleShipStats] = data["Friendly"].duplicate()
		friendly.erase(PassiveOwner)
		if (friendly.size() == 0):
			return targets
		targets.append(friendly.pick_random())
		
	else: if (Target == TargetType.RANDOM_FRIENDLY_INCLUSIVE):
		targets.append(data["Friendly"].pick_random())
		
	else: if (Target == TargetType.RANDOM_ENEMY):
		targets.append(data["Enemy"].pick_random())
		
	else: if (Target == TargetType.INSTIGATOR):
		targets.append(data["Performer"])
	
	else: if (Target == TargetType.RANDOM_SHIP):
		targets.append(data["Friendly"].pick_random())
		targets.append(data["Enemy"].pick_random())
	
	return targets

#------------------------------------------------------
enum TargetType
{
	OWNER,
	RANDOM_FRIENDLY,
	RANDOM_FRIENDLY_INCLUSIVE,
	RANDOM_ENEMY,
	INSTIGATOR,
	RANDOM_SHIP,
}

enum ReceiverType
{
	OWNER,
	ANY_FRIENDLY,
	ANY_FRIENDLY_INCLUSIVE,
	ANY_ENEMY,
	ANY_SHIP,
}

enum ActionType
{
	NONE,
	CARD_DRAWN,
	DAMAGED,
	CARD_PLAYED,
	CARD_DISCARDED,
	FIRE_CAUSED,
}

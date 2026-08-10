@abstract
extends Resource

class_name Card_Passive

@export var PassiveTrigger : ActionType = ActionType.NONE

@export var Module : CardModule
@export var Receiver : ReceiverType = ReceiverType.SELF
@export var Target : TargetType = TargetType.SELF

@abstract
func OnActionPerformed(data : Dictionary, C : CardStats, PassiveOwner : BattleShipStats) -> PassiveAnimationData
	
func GetDesc(Tier : int) -> String:
	var st : String = ActionType.keys()[PassiveTrigger]
	return "[color=#ffc315]ON {0}[/color]\n{1}".format([st.replace("_", " "),Module.GetDesc(Tier)])

@abstract
func GetTrigger() -> ActionType

func GetPossibleReceivers(data : Dictionary, PassiveOwner : BattleShipStats) -> Array[BattleShipStats]:
	var targets : Array[BattleShipStats] = []
	if (Receiver == ReceiverType.SELF):
		targets.append(PassiveOwner)
	else: if (Receiver == ReceiverType.ANY_FRIENDLY):
		var friendly : Array[BattleShipStats] = data["Friendly"].duplicate()
		friendly.erase(PassiveOwner)
		targets.append_array(friendly)
	else: if (Receiver == ReceiverType.ANY_FRIENDLY_INCLUSIVE):
		targets.append_array(data["Friendly"])
	else: if (Receiver == ReceiverType.ANY_ENEMY):
		targets.append_array(data["Enemy"])
		
	return targets

func GetPossibleTargets(data : Dictionary, PassiveOwner : BattleShipStats) -> Array[BattleShipStats]:
	var targets : Array[BattleShipStats] = []
	if (Target == TargetType.SELF):
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
	
	return targets

enum TargetType
{
	SELF,
	RANDOM_FRIENDLY,
	RANDOM_FRIENDLY_INCLUSIVE,
	RANDOM_ENEMY,
	INSTIGATOR,
}
enum ReceiverType
{
	SELF,
	ANY_FRIENDLY,
	ANY_FRIENDLY_INCLUSIVE,
	ANY_ENEMY,
	TARGET,
}

enum ActionType
{
	NONE,
	CARD_DRAW,
	DAMAGED,
	PLAYED_CARD,
	CARD_DISCARD,
}

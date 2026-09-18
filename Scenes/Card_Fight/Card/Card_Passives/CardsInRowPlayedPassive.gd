extends Card_Passive

class_name CardInRowPlayedPassive

@export var Type : CardStats.CardType = CardStats.CardType.OFFENSIVE

var lastCard : CardStats
var User : BattleShipStats

func OnActionPerformed(data : Dictionary, _C : CardStats, PassiveOwner : BattleShipStats) -> PassiveAnimationData:
	var card : CardStats = data["Card"]
	
	if (card.Type != Type):
		#reset
		User = null
		lastCard = null
		return
	
	var Instigator : BattleShipStats = data["Performer"]
	
	var possibleReceivers : Array[BattleShipStats] = GetPossibleReceivers(data, PassiveOwner)
	if (!possibleReceivers.has(Instigator)):
		return null
	
	if (User != Instigator):
		User = Instigator
		lastCard = card
		return

	#if a card has been stored by the same user
	if (lastCard == null):
		lastCard = card
		return
	
	#reset
	User = null
	lastCard = null
	
	var targets : Array[BattleShipStats] = GetPossibleTargets(data, PassiveOwner)
	
	if (targets.size() == 0):
		return null
	
	var dat : PassiveAnimationData = PassiveAnimationData.new()
	dat.Performer = data["Performer"]
	dat.Targets = targets

	return dat

#------------------------------------------------------
func GetPossibleReceivers(data : Dictionary, PassiveOwner : BattleShipStats) -> Array[BattleShipStats]:
	var actionReceiver : BattleShipStats = data["Performer"]
	var sameTeam = actionReceiver.Friendly == PassiveOwner.Friendly
	
	var targets : Array[BattleShipStats] = []
	if (Receiver == ReceiverType.OWNER):
		targets.append(PassiveOwner)
		
	else: if (Receiver == ReceiverType.ANY_FRIENDLY):
		var friendly : Array[BattleShipStats]
		if (sameTeam):
			friendly = data["Friendly"].duplicate()
		else:
			friendly = data["Enemy"].duplicate()
		friendly.erase(PassiveOwner)
		targets.append_array(friendly)
		
	else: if (Receiver == ReceiverType.ANY_FRIENDLY_INCLUSIVE):
		if (sameTeam):
			targets.append_array(data["Friendly"])
		else:
			targets.append_array(data["Enemy"])
		
		
	else: if (Receiver == ReceiverType.ANY_ENEMY):
		if (sameTeam):
			targets.append_array(data["Enemy"])
		else:
			targets.append_array(data["Friendly"])

		
	else: if (Receiver == ReceiverType.ANY_SHIP):
		targets.append_array(data["Friendly"])
		targets.append_array(data["Enemy"])
		
	return targets

func GetTrigerString() -> String:
	var triggerString : String = ActionType.keys()[GetTrigger()].replace("_", " ")
	var receiverString : String = ReceiverType.keys()[Receiver].replace("_", " ")
	
	return "[color=#ffc315]ON 2 {2} CARDS PLAYED IN A ROW BY {1}[/color]".format([triggerString, receiverString, CardStats.CardType.keys()[Type]])

func GetTrigger() -> ActionType:
	return ActionType.CARD_TYPE_IN_ROW_PLAYED

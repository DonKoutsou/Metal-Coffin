
extends Card_Passive

class_name ShieldOnDraw_Passive

@export var ShieldAmm : int = 10

@export var SelfOnly : bool
@export var OnlyFriendly : bool

func OnActionPerformed(data : Dictionary, PassiveOwner : BattleShipStats) -> PassiveAnimationData:
	if (data["actionType"] != ActionType.CARD_DRAW):
		return null
	
	if (!data["ManualDraw"]):
		return null
	
	var Performer = data["Performer"]
	
	if (SelfOnly and Performer != PassiveOwner):
		return null
	
	if (OnlyFriendly and Performer.Friendly != PassiveOwner.Friendly):
		return null
	
	#PassiveOwner.ShieldShip(ShieldAmm)
	#PassiveOwner.ShipViz.DoFloater("Shield +", Color(1,1,1))
	var Anim = PassiveAnimationData.new()
	
	var TargetViz : Array[Control]
	var Callables : Array[Callable] = []
	
	TargetViz.append(PassiveOwner.ShipViz)
	Callables.append(PassiveOwner.ShieldShip.bind(ShieldAmm))
	
	Anim.Performer = PassiveOwner
	Anim.Passive = self
	Anim.Targets = TargetViz
	Anim.Callables = Callables
	
	return Anim

func GetDesc(_Tier : int) -> String:
	if (SelfOnly):
		return "Receive shiled on drawing a card"
	
	if (OnlyFriendly):
		return "Receive shiled on team drawing a card"
		
	return "Receive shiled on any ship drawing a card"

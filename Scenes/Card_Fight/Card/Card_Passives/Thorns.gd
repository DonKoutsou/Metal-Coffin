
extends Card_Passive

class_name Thorns_Passive

@export var OnShieldDamage : bool = false
@export var OnHullDamage : bool = false

func OnActionPerformed(data : Dictionary, PassiveOwner : BattleShipStats) -> PassiveAnimationData:
	if (data["actionType"] != ActionType.DAMAGED):
		return null
	
	var Damaged : bool = false
	
	if (data["ShieldDamage"] > 0 and OnShieldDamage):
		Damaged = true
	
	if (data["Damage"] > 0 and OnHullDamage):
		Damaged = true
	
	if (!Damaged):
		return null
	
	var Instigator : BattleShipStats = data["Instigator"]
	if (Instigator == null):
		return null
		
	var Receiver : BattleShipStats = data["Receiver"]
	
	if (Receiver != PassiveOwner):
		return null
	
	var Anim = PassiveAnimationData.new()
	
	var TargetViz : Array[Control]
	var Callables : Array[Callable] = []
	
	TargetViz.append(Instigator.ShipViz)
	Callables.append(Instigator.DamageShip.bind(10, false, false))
	
	Anim.Performer = PassiveOwner
	Anim.Passive = self
	Anim.Targets = TargetViz
	Anim.Callables = Callables
	
	return Anim

func GetDesc(_Tier : int) -> String:
	return "Return Damage"

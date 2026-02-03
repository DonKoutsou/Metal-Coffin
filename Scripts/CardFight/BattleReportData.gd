extends Resource

class_name BattleReportData

@export var Won : bool
@export var FundWon : bool
@export var DamageDone : float
@export var DamageGot : float
@export var DamageNegated : float
@export var FriendlyCombatants : Array[String]
@export var EnemyCombatants : Array[String]
@export var FriendlyCasualties : Array[String]
@export var EnemyCasualties : Array[String]
@export var Location : String
@export var Date : String

func SetData(_Win : bool, DateString : String, Funds : int, DoneDmg : float, GotDmg : float, NegDmg : float, FRCombatants : Array[BattleShipStats], ENCombatants : Array[BattleShipStats],FRCasualties : Array[BattleShipStats], ENCasualties : Array[BattleShipStats], Loc : Vector2) -> void:
	for g in FRCasualties:
		FriendlyCasualties.append(g.Name)
		
	for g in ENCasualties:
		EnemyCasualties.append(g.Name)
	
	for g in FRCombatants:
		FriendlyCombatants.append(g.Name)
		
	for g in ENCombatants:
		EnemyCombatants.append(g.Name)
	
	FundWon = Funds
	DamageDone = DoneDmg
	DamageGot = GotDmg
	DamageNegated = NegDmg
	Date = DateString
	
	var closest = Helper.GetInstance().GetClosestSpot(Loc)
	if (closest.global_position.distance_squared_to(Loc) < 1000000):
		Location = "Location : {0}".format([closest.GetSpotName()])
	else:
		Location = "Location : {0} of {1}".format([Helper.AngleToDirection(closest.global_position.angle_to_point(Loc)) ,closest.GetSpotName()])

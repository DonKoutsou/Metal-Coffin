extends CardModule
class_name RecoilDamageModule

@export var RecoilPercent : int

func GetDesc(_Tier : int) -> String:
	return "[color=#ffc315]{0}%[/color] recoil damage.".format([RecoilPercent])


func GetRecoilAmmount(DamageDone : float) -> float:
	return DamageDone * (RecoilPercent as float / 100)

func NeedsTargetSelect() -> bool:
	return false

func HandleRecoil(Performer : BattleShipStats, _Action : CardStats, DamageAmm : float) -> OffensiveAnimationData:
	var Callables : Array[Callable]
	var Recoil = GetRecoilAmmount(DamageAmm)
	Callables.append(Performer.DamageShip.bind(Recoil))
	
	var AnimData = OffensiveAnimationData.new()
	AnimData.Mod = self
	
	var Data : Dictionary
	Data["Def"] = null
	Data["Viz"] = Performer.ShipViz
	var DefList : Dictionary[BattleShipStats, Dictionary]
	DefList[Performer] = Data
	AnimData.DeffenceList = DefList
	AnimData.Callables = Callables
	
	return AnimData

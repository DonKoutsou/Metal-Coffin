extends CardModule
class_name RecoilDamageModule

@export var RecoilPercent : int

func GetDesc() -> String:
	return "[color=#ffc315]{0}%[/color] recoil damage.".format([RecoilPercent])


func GetRecoilAmmount(DamageDone : float) -> float:
	return DamageDone * (RecoilPercent as float / 100)

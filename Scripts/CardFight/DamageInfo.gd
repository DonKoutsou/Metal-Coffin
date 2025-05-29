extends Resource

class_name DamageInfo

@export var ScalingStat : CardModule.Stat
@export var Method : CalcuationMethod
@export var SelfMethod : SelfCalcuationMethod

func GetDamage(DamageAmm : float, StatAmm : float) -> float:
	var StatDmg = StatAmm
	if (SelfMethod == SelfCalcuationMethod.ADD):
		StatDmg += StatDmg
	else: if (SelfMethod == SelfCalcuationMethod.MULTIPLY):
		StatDmg *= StatDmg
		
	var FinalDmg = DamageAmm * StatDmg
	
	
	
	return FinalDmg

enum CalcuationMethod {
	ADD,
	MULTIPLY,
}
enum SelfCalcuationMethod {
	NONE,
	ADD,
	MULTIPLY,
}

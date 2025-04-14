extends Resource
class_name Happening_Option

@export var OptionName : String
@export var FinishDiag : bool = false
@export_group("Branch")
@export var BranchContinuation : Array[HappeningStage]
@export_group("Worldview Effect")
@export var WorldviewEffect : WorldView.WorldViews
@export var WorldviewEffectAmm : int = 0
@export_group("Worldview Check")
@export var WorldviewCheck : WorldView.WorldViews
@export var CheckPossetive : bool
@export var CheckDifficulty : int = 20
@export var WorldViewCheckFailBranch : Array[HappeningStage]
@export var ReverseEffectOnFail :bool

var CheckResault = true

func OptionResault(EventOrigin : MapSpot) -> String:
	return ""
	
func OptionOutCome(_Instigator : MapShip)-> bool:
	if (CheckResault):
		if (WorldviewEffect != WorldView.WorldViews.NONE):
			WorldView.GetInstance().AdjustStat(WorldviewEffect, WorldviewEffectAmm, true)
	else: if (ReverseEffectOnFail):
		if (WorldviewEffect != WorldView.WorldViews.NONE):
			WorldView.GetInstance().AdjustStat(WorldviewEffect, -WorldviewEffectAmm, true)
		
	return CheckResault
		
func Check() -> bool:
	if (WorldviewCheck != WorldView.WorldViews.NONE):
		CheckResault = WorldView.GetInstance().SkillCheck(WorldviewCheck, CheckPossetive, CheckDifficulty)
	
	return CheckResault
	

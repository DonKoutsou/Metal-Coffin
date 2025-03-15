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
@export var WorldViewCheckFailBranch : Array[HappeningStage]

var CheckResault = true

func OptionResault() -> String:
	return ""
	
func OptionOutCome(_Instigator : MapShip)-> void:
	if (WorldviewEffect != WorldView.WorldViews.NONE):
		WorldView.AdjustStat(WorldviewEffect, WorldviewEffectAmm)
	
func Check() -> bool:
	
	if (WorldviewCheck != WorldView.WorldViews.NONE):
		CheckResault = WorldView.SkillCheck(WorldviewCheck, CheckPossetive)
	
	return CheckResault
	

@tool
extends Resource
class_name Happening_Option

#--------------------------------------------------
##Option Text on meni
@export var OptionName : String:
	set(value):
		OptionName = value
		emit_changed()

##Picking this option finished the dialogue
@export var FinishDiag : bool = false :
	set(value):
		FinishDiag = value
		emit_changed()
		
##Overworld event to take effect on leaving town
@export var Event : OverworldEventData

#--------------------------------------------------
##Brnahc Data
@export_group("Branch")
@export var BranchContinuation : Array[HappeningStage]
@export var Branch : HappeningStage

#--------------------------------------------------
##Worldview Effects
@export_group("Worldview Effect")
@export var WorldviewEffect : WorldView.WorldViews :
	set(value):
		WorldviewEffect = value
		emit_changed()
		
@export var WorldviewEffectAmm : int = 0:
	set(value):
		WorldviewEffectAmm = value
		emit_changed()

#--------------------------------------------------
##Worldview Check settings
@export_group("Worldview Check")
@export var WorldviewCheck : WorldView.WorldViews :
	set(value):
		WorldviewCheck = value
		emit_changed()
		
@export var CheckPossetive : bool : 
	set(value):
		CheckPossetive = value
		emit_changed()
		
@export var CheckDifficulty : int = 20 :
	set(value):
		CheckDifficulty = value
		emit_changed()
		
@export var WorldViewCheckFailBranch : Array[HappeningStage]
@export var WorldViewFailBranch : HappeningStage		
@export var ReverseEffectOnFail :bool:
	set(value):
		ReverseEffectOnFail = value
		emit_changed()

var CheckResault = true

func SameBranch(branch : HappeningStage) -> bool:
	for g in Branch.Texts:
		var matched : bool = false
		for z in branch.Texts:
			if (g.Text == z.Text):
				matched = true
				break
		if (!matched):
			return false
	print("true")	
	return true

func OptionResault(_EventOrigin : MapSpot) -> String:
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
	

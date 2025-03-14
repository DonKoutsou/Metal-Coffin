extends Resource
class_name Happening_Option

@export var OptionName : String
@export var FinishDiag : bool = false
@export var WorldviewEffect : WorldView.WorldViews
@export var WorldviewEffectAmm : int = 0
@export var WorldviewCheck : WorldView.WorldViews

func OptionResault() -> String:
	return ""
func OptionOutCome(_Instigator : MapShip)-> void:
	if (WorldviewEffect != WorldView.WorldViews.NONE):
		WorldView.AdjustStat(WorldviewEffect, WorldviewEffectAmm)
	

extends Node

class_name WorldView

static var WorldviewStats : Dictionary[WorldViews, int] = {
	WorldViews.COMPOSURE_AGITATION : 0,
	WorldViews.LOGIC_BELIEF : 0,
	WorldViews.EMPATHY_EGO : 0,
	WorldViews.FORCE_INSPIRATION : 0,
}

static func AdjustStat(Stat : WorldViews, Amm : int) -> void:
	WorldviewStats[Stat] += Amm
	print("Worldview stat {0} new value is {1}".format([WorldViews.keys()[Stat], WorldviewStats[Stat]]))
	
static func GetStatValue(StatName : WorldViews) -> int:
	return WorldviewStats[StatName]

static func SkillCheck(Stat : WorldViews, Possetive : bool) -> bool:
	var skill_value = WorldviewStats[Stat]
	
	var roll = randf_range(1, 100)
	
	var result = skill_value
	if (Possetive):
		result += roll
	else:
		result -= roll
	
	if abs(result) >= 80:
		print("Skill Check Passed!")
		return true
	else:
		print("Skill Check Failed!")
		return false

enum WorldViews{
	NONE,
	COMPOSURE_AGITATION,
	LOGIC_BELIEF,
	EMPATHY_EGO,
	FORCE_INSPIRATION,
}

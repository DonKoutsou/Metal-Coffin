extends Node

class_name WorldView

@export_group("WorldviewNotif")
@export var WorldviewAdjustNotif : PackedScene

static var WorldviewStats : Dictionary[WorldViews, int] = {
	WorldViews.COMPOSURE_AGITATION : 0,
	WorldViews.LOGIC_BELIEF : 0,
	WorldViews.EMPATHY_EGO : 0,
	WorldViews.FORCE_INSPIRATION : 0,
}

static var Instance : WorldView

func _ready() -> void:
	Instance = self

func _exit_tree() -> void:
	for g in WorldviewStats:
		WorldviewStats[g] = 0

static func GetInstance() -> WorldView:
	return Instance

func AdjustStat(Stat : WorldViews, Amm : int, Notify : bool) -> void:
	WorldviewStats[Stat] += Amm
	print("Worldview stat {0} new value is {1}".format([WorldViews.keys()[Stat], WorldviewStats[Stat]]))
	if (Notify):
		var notif = WorldviewAdjustNotif.instantiate() as WorldviewNotif
		notif.AdjustedAmm = Amm
		notif.NotifStat = Stat
		Ingame_UIManager.GetInstance().AddUI(notif, false, true)
	
func GetStatValue(StatName : WorldViews) -> int:
	return WorldviewStats[StatName]

func GetSaveData() -> Array[int]:
	var SavedStats : Array[int]
	for g in WorldviewStats:
		SavedStats.append(WorldviewStats[g])
	return SavedStats

func LoadData(SavedStats : Array[int]) -> void:
	for g in WorldviewStats.size():
		WorldviewStats[WorldviewStats.keys()[g]] = SavedStats[g]

func SkillCheck(Stat : WorldViews, Possetive : bool, Difficulty : int) -> bool:
	var skill_value = WorldviewStats[Stat]
	
	var roll = randf_range(1, 100)
	
	var result = skill_value
	if (Possetive):
		result += roll
	else:
		result -= roll
	
	if abs(result) >= Difficulty:
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

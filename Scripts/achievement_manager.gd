extends Node

class_name AchievementManager

static var Instance : AchievementManager

var SteamRunning = false

func _ready() -> void:
	Instance = self

static func GetInstance() -> AchievementManager:
	return Instance

func UlockAchievement(Name : String) -> void:
	#if (SteamRunning):
		#var AchStatus = Steam.getAchievement(Name)
		#if (AchStatus["achieved"]):
			#print(Name + " achievement already unlocked")
		#else:
			#Steam.setAchievement(Name)
			#print("Unlocked achievement :", Name)
	pass

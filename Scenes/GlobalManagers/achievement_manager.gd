extends Node

class_name AchievementManager

static var Instance : AchievementManager

var SteamRunning = false

func _ready() -> void:
	Instance = self
	

func _exit_tree() -> void:
	IncrementStatFloat("AVGT", Time.get_ticks_msec() / 60000)

static func GetInstance() -> AchievementManager:
	return Instance

func IncrementStatInt(this_stat: String, IncrementAmmount: int = 0) -> void:
	#if (SteamRunning):
		#var currentStat = Steam.getStatInt("this_stat")
		#var new_value = currentStat + IncrementAmmount
		#
		#if not Steam.setStatInt(this_stat, new_value):
			#print("Failed to set stat %s to: %s" % [this_stat, new_value])
			#return
#
		#print("Set statistics %s succesfully: %s" % [this_stat, new_value])
#
#
		##Pass the value to Steam then fire it
		#if not Steam.storeStats():
			#print("Failed to store data on Steam, should be stored locally")
			#return
#
		#print("Data successfully sent to Steam")
	pass

func IncrementStatFloat(this_stat: String, IncrementAmmount: float = 0) -> void:
	#if (SteamRunning):
		#var currentStat = Steam.getStatFloat("this_stat")
		#var new_value = currentStat + IncrementAmmount
		#
		#if not Steam.setStatFloat(this_stat, new_value):
			#print("Failed to set stat %s to: %s" % [this_stat, new_value])
			#return
#
		#print("Set statistics %s succesfully: %s" % [this_stat, new_value])
#
#
		##Pass the value to Steam then fire it
		#if not Steam.storeStats():
			#print("Failed to store data on Steam, should be stored locally")
			#return
#
		#print("Data successfully sent to Steam")
	pass

func SetStatInt(this_stat: String, new_value: int = 0) -> void:
	#if (SteamRunning):
		#if not Steam.setStatInt(this_stat, new_value):
			#print("Failed to set stat %s to: %s" % [this_stat, new_value])
			#return
#
		#print("Set statistics %s succesfully: %s" % [this_stat, new_value])
#
#
		##Pass the value to Steam then fire it
		#if not Steam.storeStats():
			#print("Failed to store data on Steam, should be stored locally")
			#return
#
		#print("Data successfully sent to Steam")
	pass

func SetStatFloat(this_stat: String, new_value: float = 0) -> void:
	#if (SteamRunning):
		#if not Steam.setStatFloat(this_stat, new_value):
			#print("Failed to set stat %s to: %s" % [this_stat, new_value])
			#return
#
		#print("Set statistics %s succesfully: %s" % [this_stat, new_value])
#
#
		##Pass the value to Steam then fire it
		#if not Steam.storeStats():
			#print("Failed to store data on Steam, should be stored locally")
			#return
#
		#print("Data successfully sent to Steam")
	pass

func UlockAchievement(Name : String) -> void:
	#if (SteamRunning):
		#var AchStatus = Steam.getAchievement(Name)
		#if (AchStatus["achieved"]):
			#print(Name + " achievement already unlocked")
		#else:
			#Steam.setAchievement(Name)
			#print("Unlocked achievement :", Name)
	pass

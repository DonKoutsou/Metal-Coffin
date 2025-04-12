extends Resource
class_name Happening

@export var HappeningName : String
@export var HappeningBg : Texture
@export var Stages : Array[HappeningStage]

@export var HappeningAppearance : GameStage
@export var Special : bool = false
@export var CrewRecruit : bool = false
var PickedBy : Array

@export var AllowedAppearances : int = 1

static var WorldSize : float = 0
#
#static var Specials : Array[Happening]
#
#func _init() -> void:
	#call_deferred("CheckIfSpecial")
	#
#func CheckIfSpecial() -> void:
	#if (Special):
		#Specials.append(self)

static func OnWorldGenerated(Size : float) -> void:
	WorldSize = Size

#static func GetStageForYPos(YPos : float) -> Happening.GameStage:
	#var GameSt : Happening.GameStage
	#if (YPos < -40000):
		#GameSt = Happening.GameStage.LATE
	#else : if (YPos < -30000):
		#GameSt = Happening.GameStage.SEMI_LATE
	#else : if (YPos < -20000):
		#GameSt = Happening.GameStage.MID
	#else : if (YPos < -10000):
		#GameSt = Happening.GameStage.SEMI_EARLY
	#else :
		#GameSt = Happening.GameStage.EARLY
	#return GameSt

static func GetStageForYPos(YPos : float) -> Happening.GameStage:
	var GameSt : Happening.GameStage
	
	# Define thresholds as percentages of the worldsize
	var late_threshold = 0.8 * WorldSize
	var semi_late_threshold = 0.6 * WorldSize
	var mid_threshold = 0.4 * WorldSize
	var semi_early_threshold = 0.2 * WorldSize

	if (YPos < late_threshold):
		GameSt = Happening.GameStage.LATE
	elif (YPos < semi_late_threshold):
		GameSt = Happening.GameStage.SEMI_LATE
	elif (YPos < mid_threshold):
		GameSt = Happening.GameStage.MID
	elif (YPos < semi_early_threshold):
		GameSt = Happening.GameStage.SEMI_EARLY
	else:
		GameSt = Happening.GameStage.EARLY
	
	return GameSt

enum GameStage
{
	EARLY,
	SEMI_EARLY,
	MID,
	SEMI_LATE,
	LATE,
	ANY
}

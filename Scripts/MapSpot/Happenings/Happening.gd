extends Resource
class_name Happening

@export var HappeningName : String
@export var HappeningBg : Texture
@export var Stages : Array[HappeningStage]

@export var HappeningAppearance : GameStage
@export var Special : bool = false
var PickedBy : MapSpot

static var Specials : Array[Happening]

func _init() -> void:
	call_deferred("CheckIfSpecial")
	
func CheckIfSpecial() -> void:
	if (Special):
		Specials.append(self)

static func GetStageForYPos(YPos : float) -> Happening.GameStage:
	var GameSt : Happening.GameStage
	if (YPos < -40000):
		GameSt = Happening.GameStage.LATE
	else : if (YPos < -30000):
		GameSt = Happening.GameStage.SEMI_LATE
	else : if (YPos < -20000):
		GameSt = Happening.GameStage.MID
	else : if (YPos < -10000):
		GameSt = Happening.GameStage.SEMI_EARLY
	else :
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

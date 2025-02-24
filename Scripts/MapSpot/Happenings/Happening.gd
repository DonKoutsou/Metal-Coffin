extends Resource
class_name Happening

@export var HappeningName : String
@export var HappeningText : String
@export var Options : Array[Happening_Option] = []
@export var HappeningAppearance : GameStage
@export var Special : bool = false
var PickedBy : MapSpot

static var Specials : Array[Happening]

func _init() -> void:
	call_deferred("CheckIfSpecial")
	
func CheckIfSpecial() -> void:
	if (Special):
		Specials.append(self)

func GetOptionsCount() -> int:
	return Options.size()

enum GameStage
{
	EARLY,
	SEMI_EARLY,
	MID,
	SEMI_LATE,
	LATE,
	ANY
}

extends Resource
class_name MapSpotType

@export var SpotK : SpotKind
@export var VisibleOnStart : bool = false
@export var BackgroundScene : PackedScene
@export var Data : MapSpotCustomData

func GetEnumString() -> String:
	return SpotKind.keys()[SpotK]

func GetSpotEnumString() -> String:
	return SpotKind.keys()[SpotK]

func GetData() -> MapSpotCustomData:
	return Data

enum SpotKind{
CITY_CENTER,
VILLAGE,
CAPITAL,
}

extends OverworldEventData

class_name OverworCityldEventData

@export var CityToFocus : String

func GetFocusPos() -> Vector2:
	return Helper.GetSpotByName(CityToFocus).global_position

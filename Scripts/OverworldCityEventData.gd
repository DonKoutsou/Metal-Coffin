extends OverworldEventData

class_name OverworCityldEventData

@export var CityToFocus : String

func GetFocusPos() -> Vector2:
	return Helper.GetInstance().GetSpotByName(CityToFocus).global_position

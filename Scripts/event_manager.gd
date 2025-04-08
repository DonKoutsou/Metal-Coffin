extends Node

class_name EventManager

@export var EventsPerSpot : Dictionary[MapSpotType.SpotKind, Array] = {
	MapSpotType.SpotKind.CITY_CENTER : [],
	MapSpotType.SpotKind.VILLAGE : [],
	MapSpotType.SpotKind.CAPITAL : []
}

static var Instance : EventManager

func _ready() -> void:
	Instance = self

static func GetInstance() -> EventManager:
	return Instance

func GetEventsForSpotType(Spot : MapSpotType.SpotKind) -> Array:
	return EventsPerSpot[Spot].duplicate()

func GetSpecialEventsForSpotType(Spot : MapSpotType.SpotKind) -> Array:
	var SpecialEvents : Array = []
	
	for g : Happening in EventsPerSpot[Spot]:
		if (g.Special):
			SpecialEvents.append(g)
	
	return SpecialEvents

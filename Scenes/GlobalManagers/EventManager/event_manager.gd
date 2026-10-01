extends Node

class_name EventManager

@export var EventList : Dictionary[MapSpotType.SpotKind, HappeningList] = {
	MapSpotType.SpotKind.CITY_CENTER : HappeningList.new(),
	MapSpotType.SpotKind.VILLAGE : HappeningList.new(),
	MapSpotType.SpotKind.CAPITAL : HappeningList.new(),
}

static var Instance : EventManager

func _ready() -> void:
	Instance = self

static func GetInstance() -> EventManager:
	return Instance

func GetEventsForSpotType(Spot : MapSpotType.SpotKind) -> Array[Happening]:
	var events : Array[Happening] = []
	
	for happeningFile : String in EventList[Spot].list:
		var hap = ResourceLoader.load(happeningFile)
		if (!hap.Special):
			events.append(hap)
		
	return events

func GetSpecialEventsForSpotType(Spot : MapSpotType.SpotKind) -> Array[Happening]:
	var SpecialEvents : Array[Happening] = []
	
	for happeningFile : String in EventList[Spot].list:
		var hap = ResourceLoader.load(happeningFile)
		if (hap.Special):
			SpecialEvents.append(hap)
	
	return SpecialEvents

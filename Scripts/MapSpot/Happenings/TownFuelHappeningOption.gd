extends String_Happening_Option
class_name TownFuelHappeningOption

@export var FuelToGive : float = 500

func OptionResault(EventOrigin : MapSpot) -> String:
	PopupManager.GetInstance().DoFadeNotif("{0} tons of fuel added to {1}'s reserve.".format([FuelToGive, EventOrigin.GetSpotName()]))
	EventOrigin.PlayerFuelReserves = FuelToGive
	
	return StringReply

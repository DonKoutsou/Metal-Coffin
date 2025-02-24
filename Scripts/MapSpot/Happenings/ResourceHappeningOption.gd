extends Happening_Option
class_name Resource_Happening_Option

@export var ResourceAmm : int = 0
@export var ResourceName : String = ""
@export var RandomiseResourceAmm : bool = false

func OptionResault() -> String:
	var returnstring : String
	if (RandomiseResourceAmm):
		var amm = randi_range(1, ResourceAmm)
		#ShipData.GetInstance().RefilResource(ResourceName, amm)
		returnstring = "You have refilled " + var_to_str(amm) + " " + ResourceName
	else:	
		#ShipData.GetInstance().RefilResource(ResourceName, ResourceAmm)
		returnstring = "You have refilled " + var_to_str(ResourceAmm) + " " + ResourceName
	return returnstring

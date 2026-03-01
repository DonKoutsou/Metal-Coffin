extends Happening_Option
class_name Item_Happening_Option

@export var HapItems : Array[Item]

func OptionResault(EventOrigin : MapSpot) -> String:
	#Inventory.GetInstance().AddItems(HapItems)
	var returnString = "You have found \n"
	var Items : Dictionary
	for g in HapItems.size():
		if (Items.keys().has(HapItems[g].ItemName)):
			Items[HapItems[g].ItemName] += 1
		else:
			Items[HapItems[g].ItemName] = 1
	
	for g in Items.keys():
		returnString += var_to_str(Items[g]) + " " + g + "\n"
		
	return returnString
